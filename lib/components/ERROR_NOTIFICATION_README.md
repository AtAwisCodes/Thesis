# Error Notification Component

A modern, simple error notification component for displaying user-friendly error messages throughout the application.

## Overview

The `ErrorNotification` component provides a consistent, visually appealing way to display error messages to users. It features:

- **Modern Design**: Clean, rounded interface with a dark theme that matches the app's aesthetic
- **Icon-based Communication**: Clear error icon for instant recognition
- **Simple Usage**: Single static method for displaying errors
- **Responsive**: Automatically handles text wrapping and adapts to screen size
- **Consistent UX**: Provides a uniform error experience across all pages

## Visual Design

- Dark background (`#2A303E`) with rounded corners
- Red error icon in a circular container with subtle background
- White text on dark background for optimal readability
- Red action button for dismissing the error
- Drop shadow for depth and emphasis

## Usage

### Basic Example

```dart
import 'package:rexplore/components/error_notification.dart';

// Display a simple error message
ErrorNotification.show(context, "Invalid email or password");
```

### In Login/Authentication Flow

```dart
try {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: emailText,
    password: passwordText,
  );
} on FirebaseAuthException catch (e) {
  if (mounted) {
    ErrorNotification.show(context, "Invalid email or password");
  }
}
```

### Multi-line Error Messages

```dart
ErrorNotification.show(
  context,
  "Disposable email addresses are not allowed.\nPlease use a permanent email address.",
);
```

### Error Validation

```dart
if (emailText.isEmpty) {
  ErrorNotification.show(context, "Please enter your email address");
  return;
}

if (passwordText.isEmpty) {
  ErrorNotification.show(context, "Please enter your password");
  return;
}
```

## Implementation Details

### Method Signature

```dart
static void show(BuildContext context, String message)
```

**Parameters:**
- `context` (BuildContext): The build context for showing the dialog
- `message` (String): The error message to display to the user

### Component Structure

The error notification uses a `Dialog` widget with:
1. **Container**: Provides styling, padding, and constraints
2. **Error Icon**: Circular container with error icon
3. **Message Text**: White text with proper line height
4. **OK Button**: Full-width red button to dismiss

## User-Friendly Error Messages

The component is designed to work with clear, actionable error messages:

### Login Errors
- ✅ "Invalid email or password"
- ✅ "No account found with this email"
- ✅ "Incorrect password"
- ✅ "This account has been disabled"
- ❌ "FirebaseAuthException: user-not-found" (too technical)

### Validation Errors
- ✅ "Please enter your email address"
- ✅ "Please enter your password"
- ✅ "Please meet all password requirements"
- ✅ "Passwords do not match"

### Network/Service Errors
- ✅ "Unable to sign in with Google. Please try again."
- ✅ "Registration failed. Please try again"
- ❌ "Error: Socket Exception..." (too technical)

## Integration with Existing Code

The component has been integrated into:

### Login Page (`lib/pages/login_page.dart`)
- Email/password validation errors
- Firebase authentication errors
- Google sign-in errors
- Disposable email errors

### Register Page (`lib/pages/register_page.dart`)
- Email validation errors
- Password requirement errors
- Age restriction errors
- Terms acceptance errors
- Google sign-in errors

## Benefits Over Previous Implementation

### Before
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    backgroundColor: Colors.deepPurple,
    title: Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  ),
);
```

**Issues:**
- No icon or visual indicator
- Generic purple background
- No clear dismiss button
- Inconsistent styling

### After
```dart
ErrorNotification.show(context, message);
```

**Improvements:**
- ✅ Clear error icon for instant recognition
- ✅ Modern dark theme with proper contrast
- ✅ Prominent dismiss button
- ✅ Consistent design across all pages
- ✅ Better visual hierarchy
- ✅ Drop shadow for emphasis
- ✅ Single line of code to use

## Customization

If you need to customize the error notification:

1. **Colors**: Edit the `color` values in `error_notification.dart`
2. **Size**: Modify `maxWidth`, `padding`, and `icon size`
3. **Border Radius**: Adjust `borderRadius` values
4. **Button Style**: Update the `ElevatedButton.styleFrom()` properties

## Best Practices

1. **Keep Messages Short**: Aim for 1-2 sentences maximum
2. **Be Specific**: Tell users exactly what went wrong
3. **Be Actionable**: Guide users on how to fix the issue
4. **Avoid Technical Jargon**: Use plain language
5. **Test Multi-line**: Ensure longer messages still look good

## Example Application

See `lib/examples/error_notification_example.dart` for interactive examples of different error scenarios.

## Accessibility

The component supports:
- Clear visual hierarchy with icons and color
- Readable text with proper contrast ratios
- Full-width button for easy tapping
- Dismissible with simple tap action

---

**Last Updated**: November 12, 2025
