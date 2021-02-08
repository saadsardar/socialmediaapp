import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social/Models/user.dart';
import 'package:social/Widgets/SuccessMessageDialog.dart';

class GiftCoinsScreen extends StatefulWidget {
  final String senderUserId;
  final String receiverUserId;
  GiftCoinsScreen({this.senderUserId, this.receiverUserId});
  @override
  _GiftCoinsScreenState createState() => _GiftCoinsScreenState();
}

class _GiftCoinsScreenState extends State<GiftCoinsScreen> {
  bool isLoading = true;
  User senderUser;
  User receiverUser;
  bool isInit = false;
  TextEditingController coinEditingController;
  FocusNode numberFocusNode;
  int coins;

  @override
  void initState() {
    coinEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    coinEditingController.dispose();
    super.dispose();
  }

  loadUsers() async {
    if (isInit == false) {
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.senderUserId)
          .get();
      senderUser = User.fromDocument(senderDoc);

      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverUserId)
          .get();
      receiverUser = User.fromDocument(receiverDoc);
      isInit = true;
    }
    setState(() {
      isLoading = false;
    });
  }

  displayReceiverUser() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width * 0.75,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: Colors.grey[300]),
      child: Text(
        'Gift Coins To \n ${receiverUser.displayName}',
        style: TextStyle(fontSize: 22),
        textAlign: TextAlign.center,
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

  Widget _amountField() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.number,
        focusNode: numberFocusNode,
        controller: coinEditingController,
        onSubmitted: (_) => numberFocusNode.unfocus(),
        decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          labelText: 'Coins',
          hintText: 'Enter Amount Of Coins',
        ),
      ),
    );
  }

  Future<String> submit() async {
    print('In Submit');
    String msg = '';
    final coinsString = coinEditingController.text;
    print(coinsString);
    coins = int.tryParse(coinsString);
    if (senderUser.coins < coins) {
      msg = 'Not Enough Coins';
    } else {
      print('In Try');
      final newSendersCoin = senderUser.coins - coins;
      final newReceiversCoin = receiverUser.coins + coins;

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(senderUser.id)
            .update({'coins': newSendersCoin});
        await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverUser.id)
            .update({'coins': newReceiversCoin});
      } catch (e) {
        msg = e.toString();
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
                          context, 'Coins Successfully Transferred');
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
                    displayReceiverUser(),
                    SizedBox(height: 10),
                    displaySenderCoins(),
                    SizedBox(height: 10),
                    _amountField(),
                    SizedBox(height: 30),
                    RaisedButton(
                        padding: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        color: Theme.of(context).primaryColor,
                        child: Text(
                          'Gift Coins',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        onPressed: () async {
                          confirmationDialogBox();
                        }),
                  ],
                ),
        ),
      ),
    );
  }
}
