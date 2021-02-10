const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { RtcTokenBuilder, RtmTokenBuilder, RtcRole, RtmRole } = require('agora-access-token');
// const stripe = require('stripe')(functions.config().stripe.testkey)
const stripe = require('stripe')('sk_test_51IGDVOGb9snCowqWKsOI25xqkKxKnNDg3lUUPHVwJ5bjTWWmQQS6bXLpZE4r29ilSf0UkmapgblXYh9SaVCiQDXD00L1lSuvJv');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
exports.onCreateFollower = functions.firestore
  .document("/followers/{userId}/userFollowers/{followerId}")
  .onCreate(async (snapshot, context) => {
    console.log("Follower Created", snapshot.id);
    const userId = context.params.userId;
    const followerId = context.params.followerId;

    // 1) Create followed users posts ref
    const followedUserPostsRef = admin
      .firestore()
      .collection("posts")
      .doc(userId)
      .collection("userPosts");

    // 2) Create following user's timeline ref
    const timelinePostsRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePosts");

    // 3) Get followed users posts
    const querySnapshot = await followedUserPostsRef.get();

    // 4) Add each user post to following user's timeline
    querySnapshot.forEach(doc => {
      if (doc.exists) {
        const postId = doc.id;
        const postData = doc.data();
        timelinePostsRef.doc(postId).set(postData);
      }
    });
  });

exports.onDeleteFollower = functions.firestore
  .document("/followers/{userId}/userFollowers/{followerId}")
  .onDelete(async (snapshot, context) => {
    console.log("Follower Deleted", snapshot.id);

    const userId = context.params.userId;
    const followerId = context.params.followerId;

    const timelinePostsRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePosts")
      .where("ownerId", "==", userId);

    const querySnapshot = await timelinePostsRef.get();
    querySnapshot.forEach(doc => {
      if (doc.exists) {
        doc.ref.delete();
      }
    });
  });

// when a post is created, add post to timeline of each follower (of post owner)
exports.onCreatePost = functions.firestore
  .document("/posts/{userId}/userPosts/{postId}")
  .onCreate(async (snapshot, context) => {
    const postCreated = snapshot.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    // 1) Get all the followers of the user who made the post
    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();
    // 2) Add new post to each follower's timeline
    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .set(postCreated);
    });
  });

exports.onUpdatePost = functions.firestore
  .document("/posts/{userId}/userPosts/{postId}")
  .onUpdate(async (change, context) => {
    const postUpdated = change.after.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    // 1) Get all the followers of the user who made the post
    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();
    // 2) Update each post in each follower's timeline
    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .get()
        .then(doc => {
          if (doc.exists) {
            doc.ref.update(postUpdated);
          }
        });
    });
  });

exports.onDeletePost = functions.firestore
  .document("/posts/{userId}/userPosts/{postId}")
  .onDelete(async (snapshot, context) => {
    const userId = context.params.userId;
    const postId = context.params.postId;

    // 1) Get all the followers of the user who made the post
    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();
    // 2) Delete each post in each follower's timeline
    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .get()
        .then(doc => {
          if (doc.exists) {
            doc.ref.delete();
          }
        });
    });
  });
exports.onCreateActivityFeedItem = functions.firestore
  .document("/feed/{userId}/feedItems/{activityFeedItem}")
  .onCreate(async (snapshot, context) => {
    console.log("Activity Feed Item Created", snapshot.data());

    // 1) Get user connected to the feed
    const userId = context.params.userId;

    const userRef = admin.firestore().doc(`users/${userId}`);
    const doc = await userRef.get();

    // 2) Once we have user, check if they have a notification token; send notification, if they have a token
    const androidNotificationToken = doc.data().androidNotificationToken;
    const createdActivityFeedItem = snapshot.data();
    if (androidNotificationToken) {
      sendNotification(androidNotificationToken, createdActivityFeedItem);
    } else {
      console.log("No token for user, cannot send notification");
    }

    function sendNotification(androidNotificationToken, activityFeedItem) {
      let body;

      // 3) switch body value based off of notification type
      switch (activityFeedItem.type) {
        case "comment":
          body = `${activityFeedItem.username} replied: ${activityFeedItem.commentData
            }`;
          break;
        case "like":
          body = `${activityFeedItem.username} liked your post`;
          break;
        case "follow":
          body = `${activityFeedItem.username} started following you`;
          break;
        default:
          break;
      }

      // 4) Create message for push notification
      const message = {
        notification: { body },
        token: androidNotificationToken,
        data: { recipient: userId }
      };

      // 5) Send message with admin.messaging()
      admin
        .messaging()
        .send(message)
        .then(response => {
          // Response is a message ID string
          console.log("Successfully sent message", response);
        })
        .catch(error => {
          console.log("Error sending message", error);
        });
    }
  });
exports.onCreateChat = functions.firestore
  .document("/chats/{to}/{from}/{messages}")
  .onCreate(async (snapshot, context) => {
    console.log("chat Item Created", snapshot.data());

    // 1) Get user connected to the feed
    const userId = context.params.to;
    console.log(userId);
    const userRef = admin.firestore().doc(`users/${userId}`);
    const doc = await userRef.get();

    // 2) Once we have user, check if they have a notification token; send notification, if they have a token
    const androidNotificationToken = doc.data().androidNotificationToken;
    const createdChatItem = snapshot.data();
    if (androidNotificationToken) {
      sendNotification(androidNotificationToken, createdChatItem);
    } else {
      console.log("No token for user, cannot send notification");
    }

    function sendNotification(androidNotificationToken, activityFeedItem) {
      let body;

      // 3) switch body value based off of notification type
      body = `${doc.username} sent: ${activityFeedItem.message
        }`;


      // 4) Create message for push notification
      const message = {
        notification: { body },
        token: androidNotificationToken,
        data: { recipient: userId }
      };

      // 5) Send message with admin.messaging()
      admin
        .messaging()
        .send(message)
        .then(response => {
          // Response is a message ID string
          console.log("Successfully sent message", response);
        })
        .catch(error => {
          console.log("Error sending message", error);
        });
    }
  });


exports.onCreateVideo = functions.firestore
  .document("/videoCall/{chatId}")
  .onCreate(async (snapshot, context) => {
    console.log("video call Item Created", snapshot.data());

    // 1) Get user connected to the feed
    const videoChatId = context.params.chatId;
    const videoRef = admin.firestore().doc(`videoCall/${videoChatId}`);
    const videodoc = await videoRef.get();

    const userId = videodoc.data().receiverId;
    console.log(userId);
    const userRef = admin.firestore().doc(`users/${userId}`);
    const doc = await userRef.get();

    // 2) Once we have user, check if they have a notification token; send notification, if they have a token
    const androidNotificationToken = doc.data().androidNotificationToken;
    const createdChatItem = snapshot.data();
    if (androidNotificationToken) {
      sendNotification(androidNotificationToken, createdChatItem);
    } else {
      console.log("No token for user, cannot send notification");
    }

    function sendNotification(androidNotificationToken, activityFeedItem) {
      let body;

      // 3) switch body value based off of notification type
      body = `${videodoc.data().hostName} is video calling you`;


      // 4) Create message for push notification
      const message = {
        notification: { body },
        token: androidNotificationToken,
        data: { recipient: userId }
      };

      // 5) Send message with admin.messaging()
      admin
        .messaging()
        .send(message)
        .then(response => {
          // Response is a message ID string
          console.log("Successfully sent message", response);
        })
        .catch(error => {
          console.log("Error sending message", error);
        });
    }
  });
exports.onNewToken = functions.https.onCall((data, context) => {
  // exports.onNewToken = async (req, res) => {
  const appID = '4422fee539f04b57a718c953f7fd7ed0';

  const appCertificate = '70d0302eef154fed8e56538b99148959';
  const channelName = data.channelName;
  console.log('Channel Name:');
  console.log(channelName);
  // const uid = parseInt(data.channelName);
  const uid = 0;
  const account = "2882341273";
  const role = RtcRole.PUBLISHER;
  const expirationTimeInSeconds = 3600
  const currentTimestamp = Math.floor(Date.now() / 1000)
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds
  // IMPORTANT! Build token with either the uid or with the user account. Comment out the option you do not want to use below.
  // Build token with uid
  const tokenA = RtcTokenBuilder.buildTokenWithUid(appID, appCertificate, channelName, uid, role, privilegeExpiredTs);
  console.log("Token With Integer Number Uid: " + tokenA);

  return { 'token': tokenA };
  // Build token with user account
  // const tokenB = RtcTokenBuilder.buildTokenWithAccount(appID, appCertificate, channelName, account, role, privilegeExpiredTs);
  // console.log("Token With UserAccount: " + tokenB);
})

// exports.StripePI = functions.https.onRequest(async (req, res) => {
exports.onStripePI = functions.https.onCall((data, context) => {

  console.log('Going For Method.create');
  const stripeVendorAccount = 'acct_123123123';
  stripe.paymentMethods.create(
    {
      payment_method: data.paym,
    }, {
    stripeAccount: stripeVendorAccount
  },
    function (err, clonedPaymentMethod) {
      if (err !== null) {
        console.log('Error clone: ', err);
        // res.send('error');
        return 'error' + err;
      } else {
        console.log('clonedPaymentMethod: ', clonedPaymentMethod);

        console.log('Returned From Method.create');
        const fee = (req.query.amount / 100) | 0;
        stripe.paymentIntents.create(
          {
            amount: data.amount,
            currency: data.currency,
            payment_method: clonedPaymentMethod.id,
            confirmation_method: 'automatic',
            confirm: true,
            application_fee_amount: fee,
            description: req.query.description,
          }, {
          stripeAccount: stripeVendorAccount
        },
          function (err, paymentIntent) {
            console.log('Function paymentIntent');
            // asynchronously called
            const paymentIntentReference = paymentIntent;
            if (err !== null) {
              console.log('Error payment Intent: ', err);
              return 'error' + err;
              // res.send('error');
            } else {
              console.log('Created paymentintent: ', paymentIntent);
              // res.json({
              console.log('Success');
              return {
                'paymentIntent': paymentIntent,
                'stripeAccount': stripeVendorAccount
              };
            }
          });

        return 'error';
        // res.send('error');

      }
    })
});

exports.createPaymentIntent = functions.https.onCall((data, context) => {
  return stripe.paymentIntents.create({
    amount: data.amount,
    currency: data.currency,
    payment_method_types: ['card'],
  });
});


const paypal = require('@paypal/payouts-sdk');
exports.createPayoutPaypal = functions.https.onCall((data, context) => {

  let clientId = "AQPWq3EqdHjXzJF2fNCp0Sr-tRDZgvalw4b-qRi27ostyfbYbX5-5dXA9Wj60Gsyo8P-CjbITCtTVbKT";
  let clientSecret = "EEn1MjVnR6-5ulxwmN74KapwWSDXGPFj6yWv5g_xoOzMqPTbvkq4DhyhEJBksfp0-IKnGEM9hLrz_MIL";
  // let environment = new paypal.core.LiveEnvironment(clientId, clientSecret);
  let environment = new paypal.core.SandboxEnvironment(clientId, clientSecret);
  let client = new paypal.core.PayPalHttpClient(environment);

  let requestBody = {
    "sender_batch_header": {
      "recipient_type": "EMAIL",
      "email_message": "SDK payouts test txn",
      "note": "Enjoy your Payout!!",
      "sender_batch_id": Date.now.toString,
      "email_subject": "Coins Redeems"
    },
    "items": [{
      "note": "Your Coins Redemtion Amount",
      "amount": {
        "currency": "USD",
        "value": data.amount
      },
      "receiver": data.emailAddress,
      "sender_item_id": "Test_txn_1"
    },
    ]
  }

  // Construct a request object and set desired parameters
  // Here, PayoutsPostRequest() creates a POST request to /v1/payments/payouts
  let request = new paypal.payouts.PayoutsPostRequest();
  request.requestBody(requestBody);

  // Call API with your client and get a response for your call
  // let createPayouts = async function () {
  try {

    client.execute(request).then((response) => {
      return { 'data': response.result };
    });
  } catch (e) {
    return { 'data': e }
  }
  // console.log(`Response: ${JSON.stringify(response)}`);
  // If call returns body in response, you can get the deserialized version from the result attribute of the response.
  // console.log(`Payouts Create Response: ${JSON.stringify(response.result)}`);
  // }
  // createPayouts();
  // return {'data': JSON.stringify(response.result)};
});