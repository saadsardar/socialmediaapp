import 'package:flutter/material.dart';
import '../Pages/home.dart';
import '../utils/settings.dart';

Widget successMessage(context, String msg) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Padding(
        padding: EdgeInsets.all(15.0),
        child: Text(
          'Success',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(15.0),
        child: Icon(
          Icons.check_box_rounded,
          color: Theme.of(context).accentColor,
          size: 40,
        ),
      ),
      Padding(
        padding: EdgeInsets.all(15.0),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 20,
          ),
        ),
      ),
      Padding(padding: EdgeInsets.only(top: 30.0)),
      FlatButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Home()),
              (Route<dynamic> route) => false);
        },
        child: Text(
          'Return To Home Screen',
          style: TextStyle(color: Colors.purple, fontSize: 18.0),
        ),
      )
    ],
  );
}

Widget errorMsg(context, String msg) {
  return
      // Dialog(
      // shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(12.0)), //this right here
      // child: Container(
      //   height: 300.0,
      //   width: 300.0,
      //   child:
      Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Padding(
        padding: EdgeInsets.all(15.0),
        child: Text(
          'UnSuccesfull',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(15.0),
        child: Icon(
          Icons.error,
          color: Theme.of(context).errorColor,
          size: 40,
        ),
      ),
      Padding(
        padding: EdgeInsets.all(15.0),
        child: Text(
          msg,
          maxLines: 3,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 20,
          ),
        ),
      ),
      Padding(padding: EdgeInsets.only(top: 30.0)),
      FlatButton(
        onPressed: () {
          // Navigator.popUntil(
          // context, ModalRoute.withName(Navigator.defaultRouteName));
          Navigator.of(context).pop();
          // Navigator.of(context, rootNavigator: true).pop(context);
          // Navigator.of(context)
          //     .popUntil(ModalRoute.withName(MainScreen.routeName));
        },
        child: Text(
          'Okay',
          style: TextStyle(color: Colors.purple, fontSize: 18.0),
        ),
      )
    ],
    //   ),
    // ),
  );
}

Widget agreeToTerms(BuildContext context, Function logout, Function sucess) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    // crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Padding(
        padding: EdgeInsets.all(15.0),
        child: Text(
          'Terms Of Use',
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(15.0),
        child: Text(
          termsOfuse,
          textAlign: TextAlign.left,
          style: TextStyle(
            // color: Theme.of(context).primaryColor,
            color: Colors.black,
            fontSize: 16,
          ),
        ),
      ),
      Padding(padding: EdgeInsets.only(top: 20.0)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FlatButton(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 1,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(50)),
            onPressed: logout,
            // () {
            // Navigator.pushAndRemoveUntil(
            //     context,
            //     MaterialPageRoute(builder: (context) => Home()),
            //     (Route<dynamic> route) => false);
            // },
            child: Text(
              'Refuse',
              style: TextStyle(
                  color: Theme.of(context).primaryColor, fontSize: 20.0),
            ),
          ),
          FlatButton(
            color: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
                // side: BorderSide(
                //     color: Colors.blue, width: 1, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(50)),
            onPressed: sucess,
            // () {
            // Navigator.pushAndRemoveUntil(
            //     context,
            //     MaterialPageRoute(builder: (context) => Home()),
            //     (Route<dynamic> route) => false);
            // },
            child: Text(
              'I Agree',
              style: TextStyle(color: Colors.white, fontSize: 20.0),
            ),
          ),
        ],
      )
    ],
  );
}
