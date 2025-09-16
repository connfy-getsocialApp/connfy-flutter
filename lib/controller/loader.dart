import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Loader extends StatelessWidget {
  Loader({this.opacity = 0.7, this.isCustom = true, this.dismissibles = false, this.color = Colors.green, this.loadingTxt = 'Loading...'});

  final bool isCustom;
  final double opacity;
  final bool dismissibles;
  final Color color;
  final String loadingTxt;
  final double _kSize = 75;
  @override
  Widget build(BuildContext context) {
    return Material(
        type: MaterialType.transparency,
        color: Colors.blue.shade300,
        child: Stack(
          children: <Widget>[
            Opacity(
              opacity: opacity,
              child: const ModalBarrier(dismissible: false, color: Colors.black),
            ),
            Center(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: isCustom
                      ? LoadingAnimationWidget.fallingDot(
                          color: Colors.blue,
                          size: _kSize,
                        )
                      : Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.only(top: 10),
                          child: CircularProgressIndicator(),
                        ),
                ),

                /*  Container(
                margin: const EdgeInsets.only(top: 5),
                child: Text(loadingTxt, style: TextStyle(color: Color(0xff009950), fontSize: 22)),
              ),*/
              ],
            )),
          ],
        ));
  }
}
