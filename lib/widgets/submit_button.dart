import 'package:flutter/material.dart';

class SubmitButton extends StatelessWidget {

  const SubmitButton({
    super.key,
    this.onTap,
    this.color,
    this.text,
    this.textColor,
    this.weight,
    this.height,
    this.width,
    this.radius,
    this.isEnable,
  });

  final void Function()? onTap;
  final Color? color;
  final String? text;
  final Color? textColor;
  final FontWeight? weight;
  final double? height;
  final double? width;
  final double? radius;
  final bool? isEnable;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
     /* onTap: isEnable ?? false ?  onTap ?? () {

      } : (){



      },*/
      child: Container(
        height: height ?? 50,
        width: width ?? size.width,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(radius ?? 10),
        ),
        child: Center(
          child: Text(
            text ?? 'SUBMIT',
            style: TextStyle(
              color: const Color(0xFF3A3939),
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: weight ?? FontWeight.w400,
              height: 0,
            ),
          ),
        ),
      ),
    );
  }
}
