const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { RtcTokenBuilder, RtmTokenBuilder, RtcRole, RtmRole } = require('agora-access-token');
// const stripe = require('stripe')(functions.config().stripe.testkey)
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

exports.StripePI = functions.https.onRequest(async (req, res) => {

  const stripeVendorAccount = 'acct_123123123';
  stripe.paymentMethods.create(
    {
      payment_method: req.query.paym,
    }, {
    stripeAccount: stripeVendorAccount
  },
    function (err, clonedPaymentMethod) {
      if (err !== null) {
        console.log('Error clone: ', err);
        res.send('error');
      } else {
        console.log('clonedPaymentMethod: ', clonedPaymentMethod);

        const fee = (req.query.amount / 100) | 0;
        stripe.paymentIntents.create(
          {
            amount: req.query.amount,
            currency: req.query.currency,
            payment_method: clonedPaymentMethod.id,
            confirmation_method: 'automatic',
            confirm: true,
            application_fee_amount: fee,
            description: req.query.description,
          }, {
          stripeAccount: stripeVendorAccount
        },
          function (err, paymentIntent) {
            // asynchronously called
            const paymentIntentReference = paymentIntent;
            if (err !== null) {
              console.log('Error payment Intent: ', err);
              res.send('error');
            } else {
              console.log('Created paymentintent: ', paymentIntent);
              res.json({
                paymentIntent: paymentIntent,
                stripeAccount: stripeVendorAccount
              });
            }
          });

        res.send('error');

      }
    })
});

// exports.StripePI = functions.https.onRequest(async (req, res) => {  res.send('error');});



