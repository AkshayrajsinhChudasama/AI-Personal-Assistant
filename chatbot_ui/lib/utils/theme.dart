import 'package:chatbot_ui/utils/colors.dart';
import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primaryColor,
  scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
  cardColor: AppColors.cardBackgroundColor,
  textTheme: const TextTheme(
    // Use updated TextStyle names according to the newer Flutter versions
    bodyLarge: TextStyle(color: AppColors.textColor), // Larger body text
    bodyMedium: TextStyle(color: AppColors.secondaryTextColor), // Medium body text
    bodySmall: TextStyle(color: AppColors.secondaryTextColor), // Smaller body text
    // You can also customize the headline, subheading, etc.
    headlineSmall: TextStyle(color: AppColors.textColor), // Large headlines
    headlineMedium: TextStyle(color: AppColors.textColor), // Smaller headlines
    // Additional customizations as required
  ),
  iconTheme: const IconThemeData(color: AppColors.iconColor),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.appBarColor,
    titleTextStyle: TextStyle(color: AppColors.textColor),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: AppColors.buttonBackgroundColor,
    textTheme: ButtonTextTheme.primary,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.dividerColor,
  ),
);

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light, // Set the theme to light
  primaryColor: AppColors.primaryColor, // Keep primary color consistent
  scaffoldBackgroundColor: AppColors.scaffoldBackgroundColorLight, // Lighter background color for the scaffold
  cardColor: AppColors.cardBackgroundColorLight, // Lighter card background color
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textColor), // Larger body text color
    bodyMedium: TextStyle(color: AppColors.secondaryTextColor), // Medium body text color
    bodySmall: TextStyle(color: AppColors.secondaryTextColor), // Smaller body text color
    headlineSmall: TextStyle(color: AppColors.textColor), // Headline text color
    headlineMedium: TextStyle(color: AppColors.textColor), // Smaller headline text color
  ),
  iconTheme: const IconThemeData(color: AppColors.iconColor), // Icon color
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.appBarColorLight, // Lighter app bar color
    titleTextStyle: TextStyle(color: AppColors.textColor), // App bar title text color
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: AppColors.buttonBackgroundColor, // Consistent button color
    textTheme: ButtonTextTheme.primary, // Text theme for the buttons
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.dividerColorLight, // Lighter divider color
  ),
);
