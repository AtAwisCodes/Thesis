# Flutter Admin Panel

A Flutter Web application for managing video reports in the ReXplore mobile app.

## Features

✅ **Secure Authentication** - Admin-only login with Firebase Auth
✅ **Real-time Dashboard** - Live updates of report statistics
✅ **Report Management** - View, filter, and manage all video reports
✅ **Video Playback** - Preview reported videos directly in the browser
✅ **Admin Actions** - Warn users, delete videos, review reports, dismiss false reports
✅ **Responsive Design** - Works on desktop, tablet, and mobile browsers
✅ **Material 3 Design** - Modern, clean UI with smooth animations

## Tech Stack

- **Flutter Web** - Cross-platform web framework
- **Firebase Auth** - Secure admin authentication
- **Cloud Firestore** - Real-time database for reports
- **Video Player** - Native video playback support
- **Material 3** - Latest Material Design components

## File Structure

```
lib/admin/
├── main_admin.dart              # Entry point for admin web app
├── admin_login_page.dart        # Login page with Firebase Auth
├── admin_dashboard_page.dart    # Main dashboard with reports list
├── report_detail_page.dart      # Detailed report view with actions
└── widgets/
    ├── stats_card.dart          # Statistics card widget
    └── report_card.dart         # Report list item widget
```

## Setup Instructions

### 1. Firebase Configuration

Make sure your Firebase project has:
- **Authentication enabled** (Email/Password provider)
- **Firestore database** with `video_reports` collection
- **Admin users** created in Firebase Console

### 2. Running the Admin Panel

#### Option A: Run from main app with route

Add to your main app's routing:

```dart
// In your main.dart or router
MaterialPageRoute(
  builder: (_) => AdminLoginPage(),
)
```

#### Option B: Run as standalone web app (Recommended)

Run the admin panel separately:

```bash
flutter run -d chrome --target=lib/admin/main_admin.dart
```

Or build for production:

```bash
flutter build web --target=lib/admin/main_admin.dart --release
```

This creates a separate `build/web` folder you can deploy to Firebase Hosting, Vercel, or any web server.

### 3. Create Admin Users

1. Go to Firebase Console → Authentication
2. Add users with admin email addresses
3. Use these credentials to login to the admin panel

### 4. Deploy to Firebase Hosting (Optional)

```bash
# Build the admin web app
flutter build web --target=lib/admin/main_admin.dart --release

# Initialize Firebase hosting (if not done)
firebase init hosting

# Deploy
firebase deploy --only hosting
```

## Usage Guide

### Login
1. Navigate to the admin panel URL
2. Enter your admin email and password
3. Click "Login to Dashboard"

### Dashboard Overview
- **Stats Cards** - Show counts for Pending, Reviewing, Resolved, and Dismissed reports
- **Filter Chips** - Click to filter reports by status
- **Report Cards** - Click any report to view details

### Managing Reports

#### View Report Details
Click on any report card to see:
- Video preview with playback controls
- Full report information
- Reporter and uploader details
- Report reason and description

#### Admin Actions

**Mark as Reviewing** (Blue button)
- Sets status to "reviewing"
- Indicates you're actively investigating

**Send Warning** (Orange button)
- Opens dialog to write custom warning message
- Sends notification to video uploader
- Marks report as "resolved"
- Keeps video online

**Delete Video** (Red button)
- Confirms deletion with dialog
- Permanently removes video from database
- Marks report as "resolved"
- Cannot be undone!

**Dismiss Report** (Gray button)
- Marks report as "dismissed"
- Use for false reports or reports that don't violate guidelines
- Video remains online

### Best Practices

1. **Review Before Action** - Always watch the reported video
2. **Document Decisions** - Use warning messages to explain violations
3. **Be Consistent** - Apply guidelines fairly across all reports
4. **Respond Quickly** - Address pending reports within 24-48 hours
5. **Use Warnings First** - Try warnings before deleting content

## Report Reasons

The system supports 7 report categories:

1. **Inappropriate Content** - Sexual, offensive, or NSFW content
2. **Spam** - Repetitive, promotional, or irrelevant content
3. **Misleading** - False information or clickbait
4. **Copyright Violation** - Unauthorized use of copyrighted material
5. **Violence** - Graphic violence or dangerous content
6. **Hate Speech** - Discriminatory or hateful content
7. **Other** - Issues not covered by other categories

## Database Structure

### video_reports Collection

```typescript
{
  reportId: string;          // Auto-generated document ID
  videoId: string;           // Reference to videos collection
  videoTitle: string;        // Title of reported video
  videoUrl: string;          // URL for video playback
  reporterId: string;        // UID of user who reported
  reporterEmail: string;     // Email of reporter
  uploaderId: string;        // UID of video uploader
  uploaderEmail: string;     // Email of uploader
  reason: string;            // Report reason enum
  description: string;       // Additional details from reporter
  status: string;            // pending|reviewing|resolved|dismissed
  createdAt: Timestamp;      // When report was created
  reviewedAt: Timestamp;     // When admin took action
  reviewedBy: string;        // Email of admin who reviewed
}
```

## Firestore Security Rules

Add these rules to protect the admin panel:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Video reports - admins only for reads/writes
    match /video_reports/{reportId} {
      allow read, write: if request.auth != null && 
        request.auth.token.email in [
          'admin@rexplore.com',
          'your-admin-email@example.com'
        ];
    }
    
    // Allow users to create reports
    match /video_reports/{reportId} {
      allow create: if request.auth != null;
    }
  }
}
```

## Keyboard Shortcuts (Coming Soon)

- `Ctrl/Cmd + F` - Focus filter search
- `Ctrl/Cmd + R` - Refresh reports
- `Escape` - Close detail view
- `→` - Next report
- `←` - Previous report

## Troubleshooting

### "No reports found"
- Check Firestore rules allow admin access
- Verify reports exist in `video_reports` collection
- Try clearing browser cache

### Video won't play
- Check video URL is valid and accessible
- Verify CORS settings on video storage
- Check browser console for errors

### Login fails
- Verify email/password in Firebase Console
- Check Firebase Auth is enabled
- Ensure admin user exists

### Reports not updating
- Check internet connection
- Verify Firestore real-time listeners are working
- Check browser console for errors

## Performance Tips

- Dashboard uses real-time listeners for live updates
- Video lazy-loads only when detail page opens
- Images and thumbnails are cached
- Pagination coming in future update

## Future Enhancements

- [ ] Bulk actions (select multiple reports)
- [ ] Advanced filtering (date range, reason, reporter)
- [ ] Export reports to CSV/PDF
- [ ] Analytics dashboard with charts
- [ ] Email notifications for new reports
- [ ] Dark mode toggle
- [ ] Search functionality
- [ ] Report templates for warnings
- [ ] Audit log for admin actions
- [ ] Mobile app version

## Support

For issues or questions:
1. Check this README
2. Review `REPORTING_SYSTEM.md` in project root
3. Check Firebase Console logs
4. Contact system administrator

## License

Part of the ReXplore project. Internal use only.
