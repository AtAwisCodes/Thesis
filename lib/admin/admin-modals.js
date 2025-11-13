// Modal System for Admin Panel
// This file contains all modal dialog functions

// Suspend User Modal
async function suspendUser(userId, userName, userEmail) {
    const content = `
        <div class="modal-header">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="#ff9800">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zM4 12c0-4.42 3.58-8 8-8 1.85 0 3.55.63 4.9 1.69L5.69 16.9C4.63 15.55 4 13.85 4 12zm8 8c-1.85 0-3.55-.63-4.9-1.69L18.31 7.1C19.37 8.45 20 10.15 20 12c0 4.42-3.58 8-8 8z"/>
            </svg>
            <div class="modal-title">Suspend User</div>
            <button class="icon-button" onclick="closeModal()">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                </svg>
            </button>
        </div>
        <div class="modal-body">
            <div class="modal-section">
                <div style="background: #f5f5f5; padding: 12px; border-radius: 8px; margin-bottom: 16px;">
                    <strong>${userName}</strong><br>
                    <span style="color: #999; font-size: 14px;">${userEmail}</span>
                </div>
                
                <label for="suspensionReason">Suspension Reason *</label>
                <textarea id="suspensionReason" placeholder="Multiple community guideline violations..." maxlength="500"></textarea>
                <div class="char-counter"><span id="reasonCount">0</span>/500</div>
            </div>
            
            <div class="modal-section">
                <label for="suspensionDays">Duration (days) *</label>
                <input type="number" id="suspensionDays" value="7" min="1" max="365" placeholder="7">
            </div>
            
            <div class="info-box">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="#1976d2">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/>
                </svg>
                <div class="info-box-content">
                    <div class="info-box-text">User will not be able to upload videos or comment during suspension.</div>
                </div>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-cancel" onclick="closeModal()">Cancel</button>
            <button class="btn btn-warning" onclick="executeSuspend('${userId}', '${userName}')">Suspend User</button>
        </div>
    `;
    
    createModal(content);
    
    document.getElementById('suspensionReason').addEventListener('input', (e) => {
        document.getElementById('reasonCount').textContent = e.target.value.length;
    });
    
    window.executeSuspend = async (uid, name) => {
        const reason = document.getElementById('suspensionReason').value.trim();
        const days = parseInt(document.getElementById('suspensionDays').value);
        
        if (!reason) {
            showErrorModal('Validation Error', 'Please enter a suspension reason.');
            return;
        }
        
        if (!days || days < 1) {
            showErrorModal('Validation Error', 'Please enter a valid duration (1-365 days).');
            return;
        }
        
        closeModal();
        showLoading();
        
        try {
            const suspensionEndDate = new Date();
            suspensionEndDate.setDate(suspensionEndDate.getDate() + days);
            
            await db.collection('users').doc(uid).update({
                isSuspended: true,
                suspensionReason: reason,
                suspendedAt: firebase.firestore.FieldValue.serverTimestamp(),
                suspendedBy: auth.currentUser.email,
                suspensionEndDate: firebase.firestore.Timestamp.fromDate(suspensionEndDate)
            });
            
            await db.collection('count').doc(uid).collection('notifications').add({
                type: 'suspension',
                title: 'Account Suspended',
                message: `Your account has been suspended for ${days} days. Reason: ${reason}`,
                suspensionEndDate: firebase.firestore.Timestamp.fromDate(suspensionEndDate),
                fromUserId: auth.currentUser.uid,
                fromUserName: 'Admin',
                fromUserAvatar: '',
                isRead: false,
                createdAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            
            hideLoading();
            showSuccessModal('User Suspended', `${name} has been suspended for ${days} days.`);
        } catch (error) {
            hideLoading();
            showErrorModal('Suspension Failed', error.message);
        }
    };
}

// Unsuspend User Modal
async function unsuspendUser(userId, userName) {
    showConfirmModal(
        'Unsuspend User',
        `Remove suspension from <strong>${userName}</strong>?<br><br>They will regain full access to the platform.`,
        'Unsuspend',
        'Cancel',
        async () => {
            showLoading();
            try {
                await db.collection('users').doc(userId).update({
                    isSuspended: false,
                    unsuspendedAt: firebase.firestore.FieldValue.serverTimestamp(),
                    unsuspendedBy: auth.currentUser.email
                });
                
                await db.collection('count').doc(userId).collection('notifications').add({
                    type: 'unsuspension',
                    title: 'Account Restored',
                    message: 'Your account suspension has been lifted. Welcome back!',
                    fromUserId: auth.currentUser.uid,
                    fromUserName: 'Admin',
                    fromUserAvatar: '',
                    isRead: false,
                    createdAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                
                hideLoading();
                showSuccessModal('User Unsuspended', `${userName}'s suspension has been removed.`);
            } catch (error) {
                hideLoading();
                showErrorModal('Unsuspend Failed', error.message);
            }
        }
    );
}

// Delete User Modal
async function deleteUser(userId, userName, userEmail) {
    const content = `
        <div class="modal-header">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="#f44336">
                <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/>
            </svg>
            <div class="modal-title">Delete User Account</div>
            <button class="icon-button" onclick="closeModal()">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                </svg>
            </button>
        </div>
        <div class="modal-body">
            <div class="modal-section">
                <div style="background: #f5f5f5; padding: 12px; border-radius: 8px; margin-bottom: 16px;">
                    <strong>${userName}</strong><br>
                    <span style="color: #999; font-size: 14px;">${userEmail}</span>
                </div>
                
                <label for="deletionReason">Deletion Reason *</label>
                <textarea id="deletionReason" placeholder="Severe violations, spam account, etc..." maxlength="500"></textarea>
                <div class="char-counter"><span id="deleteReasonCount">0</span>/500</div>
            </div>
            
            <div class="danger-box">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="#d32f2f">
                    <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/>
                </svg>
                <div class="danger-box-content">
                    <div class="danger-box-title">Warning</div>
                    <div class="danger-box-text">
                        • User will not be able to login<br>
                        • All videos will be hidden<br>
                        • Profile will be marked as deleted<br>
                        • User can be restored later if needed
                    </div>
                </div>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-cancel" onclick="closeModal()">Cancel</button>
            <button class="btn btn-danger" onclick="executeDelete('${userId}', '${userName}')">Delete Account</button>
        </div>
    `;
    
    createModal(content);
    
    document.getElementById('deletionReason').addEventListener('input', (e) => {
        document.getElementById('deleteReasonCount').textContent = e.target.value.length;
    });
    
    window.executeDelete = async (uid, name) => {
        const reason = document.getElementById('deletionReason').value.trim();
        
        if (!reason) {
            showErrorModal('Validation Error', 'Please enter a deletion reason.');
            return;
        }
        
        closeModal();
        showLoading();
        
        try {
            await db.collection('users').doc(uid).update({
                isDeleted: true,
                deletionReason: reason,
                deletedAt: firebase.firestore.FieldValue.serverTimestamp(),
                deletedBy: auth.currentUser.email
            });
            
            const videosSnapshot = await db.collection('videos')
                .where('uploaderId', '==', uid)
                .get();
            
            const batch = db.batch();
            videosSnapshot.forEach(doc => {
                batch.update(doc.ref, {
                    isDeleted: true,
                    deletedAt: firebase.firestore.FieldValue.serverTimestamp(),
                    deletedBy: auth.currentUser.email,
                    deleteReason: 'User account deleted'
                });
            });
            await batch.commit();
            
            await db.collection('count').doc(uid).collection('notifications').add({
                type: 'account_deletion',
                title: 'Account Deleted',
                message: `Your account has been deleted by admin. Reason: ${reason}`,
                fromUserId: auth.currentUser.uid,
                fromUserName: 'Admin',
                fromUserAvatar: '',
                isRead: false,
                createdAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            
            hideLoading();
            showSuccessModal('Account Deleted', `${name}'s account has been deleted successfully.`);
        } catch (error) {
            hideLoading();
            showErrorModal('Deletion Failed', error.message);
        }
    };
}

// Restore User Modal
async function restoreUser(userId, userName) {
    showConfirmModal(
        'Restore User Account',
        `Restore <strong>${userName}</strong>'s account?<br><br>They will regain access to the platform.`,
        'Restore',
        'Cancel',
        async () => {
            showLoading();
            try {
                await db.collection('users').doc(userId).update({
                    isDeleted: false,
                    restoredAt: firebase.firestore.FieldValue.serverTimestamp(),
                    restoredBy: auth.currentUser.email
                });
                
                await db.collection('count').doc(userId).collection('notifications').add({
                    type: 'account_restoration',
                    title: 'Account Restored',
                    message: 'Your account has been restored. Welcome back!',
                    fromUserId: auth.currentUser.uid,
                    fromUserName: 'Admin',
                    fromUserAvatar: '',
                    isRead: false,
                    createdAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                
                hideLoading();
                showSuccessModal('Account Restored', `${userName}'s account has been restored.`);
            } catch (error) {
                hideLoading();
                showErrorModal('Restoration Failed', error.message);
            }
        }
    );
}

// Update Bug Status Modal
async function updateBugStatus(bugId, currentStatus) {
    const content = `
        <div class="modal-header">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="#2196f3">
                <path d="M20 8h-2.81c-.45-.78-1.07-1.45-1.82-1.96L17 4.41 15.59 3l-2.17 2.17C12.96 5.06 12.49 5 12 5c-.49 0-.96.06-1.41.17L8.41 3 7 4.41l1.62 1.63C7.88 6.55 7.26 7.22 6.81 8H4v2h2.09c-.05.33-.09.66-.09 1v1H4v2h2v1c0 .34.04.67.09 1H4v2h2.81c1.04 1.79 2.97 3 5.19 3s4.15-1.21 5.19-3H20v-2h-2.09c.05-.33.09-.66.09-1v-1h2v-2h-2v-1c0-.34-.04-.67-.09-1H20V8zm-6 8h-4v-2h4v2zm0-4h-4v-2h4v2z"/>
            </svg>
            <div class="modal-title">Update Bug Report Status</div>
            <button class="icon-button" onclick="closeModal()">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                </svg>
            </button>
        </div>
        <div class="modal-body">
            <div class="modal-section">
                <label for="bugStatus">Select new status *</label>
                <select id="bugStatus">
                    <option value="pending" ${currentStatus === 'pending' ? 'selected' : ''}>PENDING</option>
                    <option value="investigating" ${currentStatus === 'investigating' ? 'selected' : ''}>INVESTIGATING</option>
                    <option value="resolved" ${currentStatus === 'resolved' ? 'selected' : ''}>RESOLVED</option>
                </select>
            </div>
            
            <div class="modal-section">
                <label for="bugNotes">Admin Notes (optional)</label>
                <textarea id="bugNotes" placeholder="Add any notes or comments..." maxlength="500"></textarea>
                <div class="char-counter"><span id="bugNotesCount">0</span>/500</div>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-cancel" onclick="closeModal()">Cancel</button>
            <button class="btn btn-primary" onclick="executeBugUpdate('${bugId}')">Update</button>
        </div>
    `;
    
    createModal(content);
    
    document.getElementById('bugNotes').addEventListener('input', (e) => {
        document.getElementById('bugNotesCount').textContent = e.target.value.length;
    });
    
    window.executeBugUpdate = async (id) => {
        const status = document.getElementById('bugStatus').value;
        const notes = document.getElementById('bugNotes').value.trim();
        
        closeModal();
        showLoading();
        
        try {
            const updateData = {
                status: status,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };
            
            if (notes) {
                updateData.adminNotes = notes;
            }
            
            await db.collection('bug_reports').doc(id).update(updateData);
            
            hideLoading();
            showSuccessModal('Status Updated', 'Bug report status updated successfully.');
        } catch (error) {
            hideLoading();
            showErrorModal('Update Failed', error.message);
        }
    };
}

// Update Feedback Status Modal
async function updateFeedbackStatus(feedbackId, currentStatus) {
    const content = `
        <div class="modal-header">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="#2196f3">
                <path d="M20 2H4c-1.1 0-1.99.9-1.99 2L2 22l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-7 9h-2V5h2v6zm0 4h-2v-2h2v2z"/>
            </svg>
            <div class="modal-title">Update Feedback Status</div>
            <button class="icon-button" onclick="closeModal()">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                </svg>
            </button>
        </div>
        <div class="modal-body">
            <div class="modal-section">
                <label for="feedbackStatus">Select new status *</label>
                <select id="feedbackStatus">
                    <option value="pending" ${currentStatus === 'pending' ? 'selected' : ''}>PENDING</option>
                    <option value="reviewed" ${currentStatus === 'reviewed' ? 'selected' : ''}>REVIEWED</option>
                    <option value="resolved" ${currentStatus === 'resolved' ? 'selected' : ''}>RESOLVED</option>
                </select>
            </div>
            
            <div class="modal-section">
                <label for="feedbackNotes">Admin Notes (optional)</label>
                <textarea id="feedbackNotes" placeholder="Add any notes or comments..." maxlength="500"></textarea>
                <div class="char-counter"><span id="feedbackNotesCount">0</span>/500</div>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-cancel" onclick="closeModal()">Cancel</button>
            <button class="btn btn-primary" onclick="executeFeedbackUpdate('${feedbackId}')">Update</button>
        </div>
    `;
    
    createModal(content);
    
    document.getElementById('feedbackNotes').addEventListener('input', (e) => {
        document.getElementById('feedbackNotesCount').textContent = e.target.value.length;
    });
    
    window.executeFeedbackUpdate = async (id) => {
        const status = document.getElementById('feedbackStatus').value;
        const notes = document.getElementById('feedbackNotes').value.trim();
        
        closeModal();
        showLoading();
        
        try {
            const updateData = {
                status: status,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };
            
            if (notes) {
                updateData.adminNotes = notes;
            }
            
            await db.collection('user_feedback').doc(id).update(updateData);
            
            hideLoading();
            showSuccessModal('Status Updated', 'Feedback status updated successfully.');
        } catch (error) {
            hideLoading();
            showErrorModal('Update Failed', error.message);
        }
    };
}

// Send Warning Modal
async function sendWarningToUploader(uploaderId, reportId, videoTitle) {
    const content = `
        <div class="modal-header">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="#ff9800">
                <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/>
            </svg>
            <div class="modal-title">Send Warning to Uploader</div>
            <button class="icon-button" onclick="closeModal()">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                </svg>
            </button>
        </div>
        <div class="modal-body">
            <div class="modal-section">
                <div style="background: #f5f5f5; padding: 12px; border-radius: 8px; margin-bottom: 16px;">
                    <strong>Video:</strong> ${videoTitle}
                </div>
                
                <label for="warningMessage">Warning Message *</label>
                <textarea id="warningMessage" placeholder="Your content has been reported for violating community guidelines..." maxlength="1000"></textarea>
                <div class="char-counter"><span id="warningCount">0</span>/1000</div>
            </div>
            
            <div class="warning-box">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="#f57c00">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/>
                </svg>
                <div class="warning-box-content">
                    <div class="warning-box-text">This warning will be sent as a notification to the video uploader.</div>
                </div>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-cancel" onclick="closeModal()">Cancel</button>
            <button class="btn btn-warning" onclick="executeWarning('${uploaderId}', '${reportId}', '${videoTitle}')">Send Warning</button>
        </div>
    `;
    
    createModal(content);
    
    document.getElementById('warningMessage').addEventListener('input', (e) => {
        document.getElementById('warningCount').textContent = e.target.value.length;
    });
    
    window.executeWarning = async (uid, rid, title) => {
        const message = document.getElementById('warningMessage').value.trim();
        
        if (!message) {
            showErrorModal('Validation Error', 'Please enter a warning message.');
            return;
        }
        
        closeModal();
        showLoading();
        
        try {
            await db.collection('count').doc(uid).collection('notifications').add({
                type: 'warning',
                title: 'Content Warning',
                message: message,
                videoId: title,
                videoTitle: title,
                reportId: rid,
                fromUserId: auth.currentUser.uid,
                fromUserName: 'Admin',
                fromUserAvatar: '',
                isRead: false,
                createdAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            
            hideLoading();
            showSuccessModal('Warning Sent', 'Warning has been sent to the uploader successfully.');
        } catch (error) {
            hideLoading();
            showErrorModal('Send Failed', error.message);
        }
    };
}

// Delete Video Modal
async function deleteVideoFromReport(videoId, reportId) {
    showConfirmModal(
        'Delete Video',
        'This will hide the video from public view. You can restore it later if needed.<br><br>Proceed with deletion?',
        'Delete',
        'Cancel',
        async () => {
            showLoading();
            try {
                await db.collection('videos').doc(videoId).update({
                    isDeleted: true,
                    deletedAt: firebase.firestore.FieldValue.serverTimestamp(),
                    deletedBy: auth.currentUser.email,
                    deleteReason: 'Reported content violation'
                });
                
                closeReportDetail();
                hideLoading();
                showSuccessModal('Video Deleted', 'Video has been deleted successfully. It can be restored if needed.');
            } catch (error) {
                hideLoading();
                showErrorModal('Delete Failed', error.message);
            }
        }
    );
}

// Restore Video Modal
async function restoreVideoFromReport(videoId, reportId) {
    showConfirmModal(
        'Restore Video',
        'This will make the video visible again to all users.<br><br>Proceed with restoration?',
        'Restore',
        'Cancel',
        async () => {
            showLoading();
            try {
                await db.collection('videos').doc(videoId).update({
                    isDeleted: false,
                    restoredAt: firebase.firestore.FieldValue.serverTimestamp(),
                    restoredBy: auth.currentUser.email
                });
                
                closeReportDetail();
                hideLoading();
                showSuccessModal('Video Restored', 'Video has been restored successfully.');
            } catch (error) {
                hideLoading();
                showErrorModal('Restore Failed', error.message);
            }
        }
    );
}

// Update Report Status
async function updateReportStatus(reportId, newStatus) {
    const statusLabels = {
        'reviewing': 'Reviewing',
        'resolved': 'Resolved',
        'dismissed': 'Dismissed'
    };
    
    showConfirmModal(
        'Update Report Status',
        `Update report status to <strong>${statusLabels[newStatus]}</strong>?`,
        'Update',
        'Cancel',
        async () => {
            showLoading();
            try {
                await db.collection('video_reports').doc(reportId).update({
                    status: newStatus,
                    reviewedBy: auth.currentUser.email,
                    reviewedAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                
                closeReportDetail();
                hideLoading();
                showSuccessModal('Status Updated', 'Report status has been updated successfully.');
            } catch (error) {
                hideLoading();
                showErrorModal('Update Failed', error.message);
            }
        }
    );
}
