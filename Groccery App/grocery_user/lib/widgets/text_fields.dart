import 'package:flutter/material.dart';
import 'package:grocery/models/state_models/theme_model.dart';

///All textFields used in the App
class TextFields {
  static Widget emailTextField({
    required TextEditingController textEditingController,
    required FocusNode focusNode,
    required TextInputAction textInputAction,
    required TextInputType textInputType,
    required String labelText,
    required IconData iconData,
    required Function onSubmitted,
    required bool error,
    required bool isLoading,
    required ThemeModel themeModel,
    bool obscureText = false,
  }) {
    return Container(
      margin: EdgeInsets.only(
        top: 10,
      ),
      padding: EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
        color: themeModel.secondBackgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        border: Border.all(
            width: 1, color: error ? Colors.red : themeModel.borderColor),
      ),
      child: TextField(
        enabled: !isLoading,
        obscureText: obscureText,
        controller: textEditingController,
        focusNode: focusNode,
        textInputAction: textInputAction,
        keyboardType: textInputType,
        onSubmitted: (value) {
          onSubmitted();
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          labelText: labelText,
          icon: Icon(iconData),
        ),
      ),
    );
  }

  static Widget searchTextField({
    required TextEditingController textEditingController,
    required Function(String value) onSubmitted,
    required Function(String value) onChanged,
    required ThemeModel themeModel,
  }) {
    return Container(
      margin: EdgeInsets.only(
        top: 10,
      ),
      padding: EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
          color: themeModel.secondBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          border: Border.all(
            color: themeModel.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
                blurRadius: 4,
                offset: Offset(0, 2),
                color: themeModel.shadowColor)
          ]),
      child: TextField(
        textCapitalization: TextCapitalization.words,
        controller: textEditingController,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        decoration: InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            hintText: 'Search..'),
      ),
    );
  }

  static Widget addressTextField({
    required ThemeModel themeModel,
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextInputType textInputType,
    required TextInputAction textInputAction,
    required String labelText,
    required Function(String) onSubmitted,
    required bool error,
    required enabled,
    bool obscureText = false,
  }) {
    return Container(
      margin: EdgeInsets.only(
          //  bottom: 10
          ),
      decoration: BoxDecoration(
          color: themeModel.secondBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          border: Border.all(
              color: (error) ? Colors.red : themeModel.borderColor,
              width: 1)),
      padding: EdgeInsets.all(10),
      child: TextField(
        enabled: enabled,
        textCapitalization: TextCapitalization.words,
        keyboardType: textInputType,
        textInputAction: textInputAction,
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        onChanged: (value) {},
        decoration: InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            labelText: labelText,
            contentPadding: EdgeInsets.only(left: 20, right: 20)),
      ),
    );
  }
}
