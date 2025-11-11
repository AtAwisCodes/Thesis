# System Report Feature Documentation

## Overview
The System Report feature allows users to report issues related to system maintenance, performance, and technical problems directly to the admin panel. This provides a streamlined way for administrators to track and resolve user-reported issues.

## User Features

### Reporting a System Issue
1. **Access the Report Dialog**:
   - Open the drawer menu from the home page
   - Tap on "Report System Issue"

2. **Fill in the Report Form**:
   - **Category** (Required): Select one of the following:
     - System Maintenance
     - Performance Issues
     - Technical Issues
     - Feature Request
     - Other
   
   - **Title** (Required): Brief summary of the issue (max 100 characters)
   
   - **Description** (Required): Detailed description of the issue (max 1000 characters)

3. **Submit the Report**:
   - Click "Submit Report"
   - A confirmation message will appear: "Thank you for the feedback!"

## Admin Features

### Viewing System Reports
1. **Access System Reports**:
   - Login to the admin panel
   - Click the bug report icon (🐛) in the app bar
   - This opens the System Reports page

2. **Report Dashboard**:
   - View statistics for:
     - Pending reports
     - Reviewing reports
     - Resolved reports
     - Dismissed reports
   
3. **Filter Reports**:
   - Click on any stat card to filter by status
   - Use filter chips to switch between statuses
   - View all reports or filter by specific status

### Managing System Reports
1. **View Report Details**:
   - Click on any report card to open detailed view
   - View full information including:
     - Status
     - Category
     - Title
     - Description
     - Reporter information
     - Date reported

2. **Update Report Status**:
   - **Mark as Reviewing**: Indicates admin is investigating
   - **Mark as Resolved**: Issue has been fixed
   - **Dismiss**: Issue is not valid or not applicable

3. **Add Admin Notes**:
   - Add internal notes about the report
   - Notes are saved when updating status

## Technical Implementation

### Files Created/Modified

#### New Files:
1. **`lib/components/system_report_dialog.dart`**
   - User-facing dialog for submitting system reports
   - Form validation
   - Success notification

2. **`lib/admin/system_reports_page.dart`**
   - Admin interface for viewing and managing system reports
   - Statistics dashboard
   - Filtering capabilities
   - Report detail dialog

#### Modified Files:
1. **`lib/services/report_service.dart`**
   - Added `SystemReportCategory` enum
   - Added `reportSystemIssue()` method
   - Added `streamSystemReports()` method
   - Added `updateSystemReportStatus()` method

2. **`lib/admin/admin_dashboard_page.dart`**
   - Added bug report icon to app bar
   - Links to System Reports page

3. **`lib/pages/home_page.dart`**
   - Added "Report System Issue" menu item in drawer
   - Opens system report dialog

### Database Structure

#### Collection: `system_reports`
```
{
  reporterId: string,
  reporterName: string,
  reporterEmail: string,
  category: string (maintenance, performance, technicalIssue, featureRequest, other),
  categoryDisplay: string,
  title: string,
  description: string,
  status: string (pending, reviewing, resolved, dismissed),
  createdAt: timestamp,
  updatedAt: timestamp,
  adminNotes: string,
  resolvedAt: timestamp (nullable),
  resolvedBy: string (nullable)
}
```

## Report Categories

### System Maintenance
- Issues related to system updates
- Database maintenance concerns
- Service interruptions

### Performance Issues
- Slow loading times
- App crashes
- Memory issues
- Lag or freezing

### Technical Issues
- Bugs and errors
- Feature malfunctions
- Unexpected behavior
- Integration problems

### Feature Request
- Suggestions for new features
- Improvements to existing functionality

### Other
- Any other concerns not covered above

## Workflow

### User Workflow:
1. User encounters an issue
2. Opens drawer → "Report System Issue"
3. Selects category and fills form
4. Submits report
5. Receives thank you notification

### Admin Workflow:
1. Admin logs into admin panel
2. Clicks bug report icon
3. Views all system reports
4. Filters by status if needed
5. Clicks on report to view details
6. Adds admin notes
7. Updates status (Reviewing → Resolved)
8. Report is tracked for analytics

## Benefits

### For Users:
- Easy way to report issues
- Direct communication with admin
- Acknowledgment of feedback

### For Admins:
- Centralized issue tracking
- Organized by category and status
- Historical record of issues
- Better system maintenance

## Future Enhancements

Potential improvements:
- Email notifications to admins when new reports arrive
- Priority levels for urgent issues
- Response time tracking
- User notification when report is resolved
- Analytics and reporting dashboard
- Export reports to CSV/PDF
