import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:social/Models/user.dart';
import 'package:social/Widgets/SuccessMessageDialog.dart';

class GiftRedeem {
  int coins;
  double amount;
  GiftRedeem({this.coins, this.amount});
}

class RedeemCoinsScreen extends StatefulWidget {
  final String senderUserId;
  // final String receiverUserId;
  RedeemCoinsScreen({this.senderUserId});
  @override
  _RedeemCoinsScreenState createState() => _RedeemCoinsScreenState();
}

class _RedeemCoinsScreenState extends State<RedeemCoinsScreen> {
  bool isLoading = true;
  User senderUser;
  // User receiverUser;
  bool isInit = false;
  TextEditingController emailEditingController;
  FocusNode emailFocusNode;
  final List<GiftRedeem> _gifts = [
    GiftRedeem(coins: 4000, amount: 20),
    GiftRedeem(coins: 10000, amount: 50),
    GiftRedeem(coins: 20000, amount: 100),
    GiftRedeem(coins: 40000, amount: 200),
    GiftRedeem(coins: 100000, amount: 500),
  ];
  GiftRedeem _selectedGift;
  final HttpsCallable intent =
      FirebaseFunctions.instance.httpsCallable('createPayoutPaypal');

  @override
  void initState() {
    emailEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    emailEditingController.dispose();
    super.dispose();
  }

  loadUsers() async {
    if (isInit == false) {
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.senderUserId)
          .get();
      senderUser = User.fromDocument(senderDoc);
      isInit = true;
    }
    setState(() {
      isLoading = false;
    });
  }

  displayGiftItem(GiftRedeem giftItem) {
    return GestureDetector(
      onTap: () {
        if (giftItem.coins >= senderUser.coins) {
          setState(() {
            _selectedGift = giftItem;
          });
        }
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
                'Redeem ${giftItem.coins} For \$${giftItem.amount.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  displaySenderCoins() {
    return Container(
      height: 50,
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width * 0.75,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: Colors.grey[300]),
      child: Text(
        'Available Coins: ${senderUser.coins}',
        style: TextStyle(fontSize: 22),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _emailField() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.emailAddress,
        focusNode: emailFocusNode,
        controller: emailEditingController,
        onSubmitted: (_) => emailFocusNode.unfocus(),
        decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          labelText: 'Enter PayPal Registered  Email Address',
          hintText: 'Email Address',
        ),
      ),
    );
  }

  Future<String> submit() async {
    print('In Submit');
    String msg = '';
    final emailAddress = emailEditingController.text;
    print(emailAddress);
    if (
        // senderUser.coins < _selectedGift.coins ||
        emailAddress.length == 0 || emailAddress == null) {
      msg = 'Not Enough Coins';
    } else {
      final newSendersCoin = senderUser.coins - _selectedGift.coins;

      try {
        print('In Try');
        final HttpsCallableResult result = await intent.call(
          <String, dynamic>{
            'emailAddress': emailAddress,
            'amount': _selectedGift.amount.toStringAsFixed(0),
            // 'amount': '1.50',
          },
        );
        print(result.data);
        final data = result.data as Map<dynamic, dynamic>;

        if (data['batch_status'] != 'PENDING') {
          msg =
              'Your Request Can not be processed at the at the moment. Please try again later';
        } else {
          // print(result.data);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(senderUser.id)
              .update({'coins': newSendersCoin});
        }
      } catch (e) {
        print('$e');
        msg =
            'Your Request Can not be processed at the at the moment. Please try again later';
        // msg = e.toString();
      }
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    loadUsers();

    Future<void> confirmationDialogBox() async {
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
                future: submit(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    print('Snap Data ${snap.data}');
                    final msg = snap.data ?? 'Error';
                    // final msg = 'abc';
                    if (msg == '') {
                      return successMessage(
                          context, 'Redeem Request Successfully Submitted');
                    } else {
                      return errorMsg(context, msg);
                    }
                  }
                }),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: isLoading
              ? CircularProgressIndicator()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // displayReceiverUser(),
                    SizedBox(height: 10),
                    displaySenderCoins(),

                    for (var giftItem in _gifts) displayGiftItem(giftItem),
                    SizedBox(height: 10),
                    _emailField(),
                    SizedBox(height: 30),
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
                        onPressed: _selectedGift == null
                            ? null
                            : () async {
                                // submit();
                                confirmationDialogBox();
                              }),
                  ],
                ),
        ),
      ),
    );
  }
}
