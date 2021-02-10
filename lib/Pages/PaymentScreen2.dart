import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:social/Models/user.dart';
import 'package:social/Pages/RedeemCoinsScreen.dart';
import 'package:social/Widgets/SuccessMessageDialog.dart';
import 'package:stripe_payment/stripe_payment.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'PaypalPayment.dart';

class GiftPurchase {
  int coins;
  double amount;
  GiftPurchase({this.coins, this.amount});
}

class PaymentScreen2 extends StatefulWidget {
  final String currentUserId;
  PaymentScreen2({this.currentUserId});
  @override
  _PaymentScreen2State createState() => _PaymentScreen2State();
}

class _PaymentScreen2State extends State<PaymentScreen2> {
  final List<GiftPurchase> _gifts = [
    GiftPurchase(coins: 60, amount: 0.99),
    GiftPurchase(coins: 303, amount: 4.95),
    GiftPurchase(coins: 3099, amount: 49.99),
  ];

  User currentUser;
  GiftPurchase _selectedGift;
  bool isLoading = false;
  bool isInit = false;
  bool isInitLoading = true;
  final HttpsCallable intent =
      FirebaseFunctions.instance.httpsCallable('createPaymentIntent');

  @override
  void initState() {
    StripePayment.setOptions(StripeOptions(
        publishableKey:
            "pk_test_51IGDVOGb9snCowqWnQ8VfI6d6wsiWBq63TRjN8Cx4FLtZr6L89JfbZGda7I3yMDeqjrwtbuxecnSx7CWBHqhOzau00rOK6MsDd"));
    super.initState();
  }

  loadUsers() async {
    if (isInit == false) {
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      currentUser = User.fromDocument(senderDoc);

      isInit = true;
    }
    setState(() {
      isInitLoading = false;
    });
  }

  Future<void> addPaymentDetailsToFirestore() async {
    print('In Firebase Func');
    final foundUser = await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser.id)
        .get();
    final userData = foundUser.data();
    userData['coins'] += _selectedGift.coins;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .update(userData);
    currentUser.coins += _selectedGift.coins;
  }

  Future<String> confirmPayment(String sec, PaymentMethod paymentMethod) async {
    print('Payment Confirmed');
    final val = await StripePayment.confirmPaymentIntent(
      PaymentIntent(clientSecret: sec, paymentMethodId: paymentMethod.id),
    );
    addPaymentDetailsToFirestore();
    print(val);
    print('Payment Done');
    return '';
    // final snackBar = SnackBar(
    //   content: Text('Payment Successfull'),
    // );
    // Scaffold.of(context).showSnackBar(snackBar);
    // });
  }

  Future<void> _showMyDialog(
      String clientSecret, PaymentMethod paymentMethod) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Container(
          height: 350.0,
          width: 300.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(15.0),
                child: Text(
                  'Confirm Purchase',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // color: Theme.of(context).primaryColor,
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(15.0),
                child: Text(
                  'Purchase ${_selectedGift.coins} Coins For \$${_selectedGift.amount.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // color: Theme.of(context).primaryColor,
                    color: Theme.of(context).accentColor,
                    fontSize: 20,
                  ),
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 30.0)),
              FlatButton(
                child: Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Center(
                    child: Text(
                      'Confirm',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 20.0),
                    ),
                  ),
                ),
                onPressed: () async {
                  confirmationDialogBox(clientSecret, paymentMethod);
                },
              ),
              SizedBox(height: 15),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 18.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> confirmationDialogBox(
      String clientSecret, PaymentMethod paymentMethod) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Container(
          height: 400.0,
          width: 300.0,
          child: FutureBuilder(
              future: confirmPayment(clientSecret, paymentMethod),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  print('Snap Data ${snap.data}');
                  final msg = snap.data as String ?? 'Error';
                  // final msg = 'abc';
                  if (msg == '') {
                    return successMessage(context,
                        'Payment Successfull, your Coins are Added Into your wallet');
                  } else {
                    return errorMsg(context, msg);
                  }
                }
              }),
        ),
      ),
    );
  }

  Future<void> getPayIntent() async {
    if (_selectedGift == null) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      final paymentMethod = await StripePayment.paymentRequestWithCardForm(
          CardFormPaymentRequest());
      print('paymentRequestWithCardForm done');
      double amount = _selectedGift.amount *
          100.0; // multipliying with 100 to change $ to cents
      final response = await intent
          .call(<String, dynamic>{'amount': amount, 'currency': 'usd'});
      _showMyDialog(response.data["client_secret"], paymentMethod);
    } catch (e) {
      print(e);
    }

    setState(() {
      isLoading = false;
    });
  }

  displayGiftItem(GiftPurchase giftItem) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGift = giftItem;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
          color:
              _selectedGift == giftItem ? Colors.grey[400] : Colors.grey[300],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 25.0),
              child: Image.asset(
                'assets/images/coin.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                'Get ${giftItem.coins} For \$${giftItem.amount.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userCoins() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        border: Border.all(width: 1, color: Theme.of(context).primaryColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Available Coins',
            style: TextStyle(fontSize: 22),
          ),
          Text(
            '${currentUser.coins}',
            style: TextStyle(fontSize: 27),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    loadUsers();
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallet'),
      ),
      body: SingleChildScrollView(
        child: isInitLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  SizedBox(height: 20),
                  userCoins(),
                  SizedBox(height: 20),
                  RaisedButton(
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      color: Theme.of(context).primaryColor,
                      child: Text(
                        'Redeem Coins',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      onPressed: () async {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => RedeemCoinsScreen(
                                  senderUserId: currentUser.id,
                                )));
                        // getPayIntent();
                      }),
                  SizedBox(height: 20),
                  for (var giftItem in _gifts) displayGiftItem(giftItem),
                  // ListView.builder(
                  //     itemCount: _gifts.length,
                  //     itemBuilder: (ctx, i) => displayGiftItem(_gifts[i])),
                  SizedBox(
                    height: 20,
                  ),
                  isLoading
                      ? CircularProgressIndicator()
                      : RaisedButton(
                          padding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                          color: Theme.of(context).primaryColor,
                          child: Text(
                            'Purchase Gift',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          onPressed: _selectedGift != null
                              ? () async {
                                  //   Navigator.of(context).push(
                                  //     MaterialPageRoute(
                                  //       builder: (BuildContext context) =>
                                  //           PaypalPayment(
                                  //         amount: _selectedGift.amount.toString(),
                                  //         item: '${_selectedGift.coins} Coins',
                                  //         onFinish: (number) async {
                                  //           // payment done
                                  //           print('order id: ' + number);
                                  //         },
                                  //       ),
                                  //     ),
                                  //   );
                                  getPayIntent();
                                }
                              : null,
                        )
                ],
              ),
      ),
    );
  }
}
