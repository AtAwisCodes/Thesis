// Import modal functions - make sure admin-modals.js is loaded first in HTML
// Firebase Configuration
const firebaseConfig = {
    apiKey: 'AIzaSyC6JbC573Ysu_ZrvPF4Ua2EhD8bwzqpUio',
    authDomain: 'rexplore-61772.firebaseapp.com',
    projectId: 'rexplore-61772',
    storageBucket: 'rexplore-61772.firebasestorage.app',
    messagingSenderId: '265429004049',
    appId: '1:265429004049:web:YOUR_WEB_APP_ID'
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const db = firebase.firestore();

// Set persistence
auth.setPersistence(firebase.auth.Auth.Persistence.LOCAL);

// Global State
let currentPage = 'video_reports';
let currentFilter = 'all';
let unsubscribeListeners = [];

// Modal System
const modalContainer = document.getElementById('modalContainer');

function createModal(content) {
    const modalHtml = `
        <div class="modal-overlay" onclick="closeModal(event)">
            <div class="modal" onclick="event.stopPropagation()">
                ${content}
            </div>
        </div>
    `;
    modalContainer.innerHTML = modalHtml;
}

function closeModal(event) {
    if (event && event.target.className !== 'modal-overlay') return;
    modalContainer.innerHTML = '';
}

function showConfirmModal(title, message, confirmText, cancelText, onConfirm) {
    const content = `
        <div class="modal-header">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="#ff9800">
                <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/>
            </svg>
            <div class="modal-title">${title}</div>
        </div>
        <div class="modal-body">
            <p style="line-height: 1.6; color: #666;">${message}</p>
        </div>
        <div class="modal-footer">
            <button class="btn btn-cancel" onclick="closeModal()">${cancelText}</button>
            <button class="btn btn-primary" onclick="confirmAction()">${confirmText}</button>
        </div>
    `;
    createModal(content);
    window.confirmAction = () => {
        closeModal();
        if (onConfirm) onConfirm();
    };
}

function showErrorModal(title, message) {
    const content = `
        <div class="modal-header">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="#f44336">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/>
            </svg>
            <div class="modal-title">${title}</div>
        </div>
        <div class="modal-body">
            <p style="line-height: 1.6; color: #d32f2f;">${message}</p>
        </div>
        <div class="modal-footer">
            <button class="btn btn-primary" onclick="closeModal()">OK</button>
        </div>
    `;
    createModal(content);
}

function showSuccessModal(title, message) {
    const content = `
        <div class="modal-header">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="#4caf50">
                <path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/>
            </svg>
            <div class="modal-title">${title}</div>
        </div>
        <div class="modal-body">
            <p style="line-height: 1.6; color: #2e7d32;">${message}</p>
        </div>
        <div class="modal-footer">
            <button class="btn btn-success" onclick="closeModal()">OK</button>
        </div>
    `;
    createModal(content);
}

// DOM Elements
const loginPage = document.getElementById('loginPage');
const dashboardPage = document.getElementById('dashboardPage');
const loginForm = document.getElementById('loginForm');
const loginButton = document.getElementById('loginButton');
const loginText = document.getElementById('loginText');
const loginLoader = document.getElementById('loginLoader');
const errorMessage = document.getElementById('errorMessage');
const contentArea = document.getElementById('contentArea');
const logoutButton = document.getElementById('logoutButton');
const adminEmail = document.getElementById('adminEmail');
const topBarEmail = document.getElementById('topBarEmail');
const pageTitle = document.getElementById('pageTitle');
const pageTitleIcon = document.getElementById('pageTitleIcon');
const loadingOverlay = document.getElementById('loadingOverlay');

// Authentication State Observer
auth.onAuthStateChanged((user) => {
    if (user) {
        showDashboard(user);
    } else {
        showLogin();
    }
});

// Login Form Handler
loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    
    loginButton.disabled = true;
    loginText.style.display = 'none';
    loginLoader.style.display = 'block';
    errorMessage.style.display = 'none';
    
    try {
        await auth.signInWithEmailAndPassword(email, password);
    } catch (error) {
        showError(error.message);
        loginButton.disabled = false;
        loginText.style.display = 'block';
        loginLoader.style.display = 'none';
    }
});

// Logout Handler
logoutButton.addEventListener('click', async () => {
    showConfirmModal(
        'Logging Out',
        'Are you sure you want to logout?',
        'Logout',
        'Cancel',
        async () => {
            try {
                await auth.signOut();
            } catch (error) {
                showErrorModal('Logout Error', error.message);
            }
        }
    );
});

// Navigation Handler
document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', (e) => {
        e.preventDefault();
        const page = item.getAttribute('data-page');
        navigateToPage(page);
    });
});

function showLogin() {
    loginPage.style.display = 'flex';
    dashboardPage.style.display = 'none';
    loginForm.reset();
}

function showDashboard(user) {
    loginPage.style.display = 'none';
    dashboardPage.style.display = 'block';
    adminEmail.textContent = user.email;
    topBarEmail.textContent = user.email;
    loadPage(currentPage);
}

function showError(message) {
    errorMessage.innerHTML = `
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/>
        </svg>
        ${message}
    `;
    errorMessage.style.display = 'flex';
}

function navigateToPage(page) {
    currentPage = page;
    currentFilter = 'all';
    
    // Update navigation
    document.querySelectorAll('.nav-item').forEach(item => {
        if (item.getAttribute('data-page') === page) {
            item.classList.add('active');
        } else {
            item.classList.remove('active');
        }
    });
    
    // Update page title
    const titles = {
        video_reports: 'Video Reports',
        bug_reports: 'Bug Reports',
        user_feedback: 'User Feedback',
        user_management: 'User Management'
    };
    
    const icons = {
        video_reports: '<path d="M4 6h16v2H4zm0 5h16v2H4zm0 5h16v2H4z"/>',
        bug_reports: '<path d="M20 8h-2.81c-.45-.78-1.07-1.45-1.82-1.96L17 4.41 15.59 3l-2.17 2.17C12.96 5.06 12.49 5 12 5c-.49 0-.96.06-1.41.17L8.41 3 7 4.41l1.62 1.63C7.88 6.55 7.26 7.22 6.81 8H4v2h2.09c-.05.33-.09.66-.09 1v1H4v2h2v1c0 .34.04.67.09 1H4v2h2.81c1.04 1.79 2.97 3 5.19 3s4.15-1.21 5.19-3H20v-2h-2.09c.05-.33.09-.66.09-1v-1h2v-2h-2v-1c0-.34-.04-.67-.09-1H20V8zm-6 8h-4v-2h4v2zm0-4h-4v-2h4v2z"/>',
        user_feedback: '<path d="M20 2H4c-1.1 0-1.99.9-1.99 2L2 22l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-7 9h-2V5h2v6zm0 4h-2v-2h2v2z"/>',
        user_management: '<path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/>'
    };
    
    pageTitle.textContent = titles[page];
    pageTitleIcon.innerHTML = icons[page];
    
    loadPage(page);
}

function loadPage(page) {
    // Clear existing listeners
    unsubscribeListeners.forEach(unsubscribe => unsubscribe());
    unsubscribeListeners = [];
    
    contentArea.innerHTML = '';
    
    switch (page) {
        case 'video_reports':
            loadVideoReports();
            break;
        case 'bug_reports':
            loadBugReports();
            break;
        case 'user_feedback':
            loadUserFeedback();
            break;
        case 'user_management':
            loadUserManagement();
            break;
    }
}

// Video Reports Page
function loadVideoReports() {
    const stats = { pending: 0, reviewing: 0, resolved: 0, dismissed: 0 };
    
    const unsubscribe = db.collection('video_reports')
        .orderBy('createdAt', 'desc')
        .onSnapshot((snapshot) => {
            const allReports = [];
            snapshot.forEach(doc => {
                const data = doc.data();
                const videoUrl = data.videoUrl || '';
                // Filter out YouTube videos
                if (!videoUrl.includes('youtube.com') && !videoUrl.includes('youtu.be')) {
                    allReports.push({ id: doc.id, ...data });
                }
            });
            
            // Update stats
            stats.pending = allReports.filter(r => r.status === 'pending').length;
            stats.reviewing = allReports.filter(r => r.status === 'reviewing').length;
            stats.resolved = allReports.filter(r => r.status === 'resolved').length;
            stats.dismissed = allReports.filter(r => r.status === 'dismissed').length;
            
            // Filter reports
            const filteredReports = currentFilter === 'all' 
                ? allReports 
                : allReports.filter(r => r.status === currentFilter);
            
            renderVideoReportsPage(stats, filteredReports);
        });
    
    unsubscribeListeners.push(unsubscribe);
}

function renderVideoReportsPage(stats, reports) {
    contentArea.innerHTML = `
        <!-- Stats Cards -->
        <div class="stats-grid">
            <div class="stat-card" style="border-color: #ff9800;" onclick="setFilter('pending')">
                <div class="stat-card-header">
                    <div class="stat-icon" style="background: rgba(255, 152, 0, 0.1);">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="#ff9800">
                            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                        </svg>
                    </div>
                    <div class="stat-count" style="color: #ff9800;">${stats.pending}</div>
                </div>
                <div class="stat-title">Pending</div>
            </div>
            
            <div class="stat-card" style="border-color: #2196f3;" onclick="setFilter('reviewing')">
                <div class="stat-card-header">
                    <div class="stat-icon" style="background: rgba(33, 150, 243, 0.1);">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="#2196f3">
                            <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"/>
                        </svg>
                    </div>
                    <div class="stat-count" style="color: #2196f3;">${stats.reviewing}</div>
                </div>
                <div class="stat-title">Reviewing</div>
            </div>
            
            <div class="stat-card" style="border-color: #4caf50;" onclick="setFilter('resolved')">
                <div class="stat-card-header">
                    <div class="stat-icon" style="background: rgba(76, 175, 80, 0.1);">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="#4caf50">
                            <path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/>
                        </svg>
                    </div>
                    <div class="stat-count" style="color: #4caf50;">${stats.resolved}</div>
                </div>
                <div class="stat-title">Resolved</div>
            </div>
            
            <div class="stat-card" style="border-color: #f44336;" onclick="setFilter('dismissed')">
                <div class="stat-card-header">
                    <div class="stat-icon" style="background: rgba(244, 67, 54, 0.1);">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="#f44336">
                            <path d="M12 2C6.47 2 2 6.47 2 12s4.47 10 10 10 10-4.47 10-10S17.53 2 12 2zm5 13.59L15.59 17 12 13.41 8.41 17 7 15.59 10.59 12 7 8.41 8.41 7 12 10.59 15.59 7 17 8.41 13.41 12 17 15.59z"/>
                        </svg>
                    </div>
                    <div class="stat-count" style="color: #f44336;">${stats.dismissed}</div>
                </div>
                <div class="stat-title">Dismissed</div>
            </div>
        </div>
        
        <!-- Filter Section -->
        <div class="filter-section">
            <div class="filter-title">Filter by Status</div>
            <div class="filter-chips">
                <span class="filter-chip ${currentFilter === 'all' ? 'active' : ''}" onclick="setFilter('all')">All Reports</span>
                <span class="filter-chip ${currentFilter === 'pending' ? 'active' : ''}" onclick="setFilter('pending')">Pending</span>
                <span class="filter-chip ${currentFilter === 'reviewing' ? 'active' : ''}" onclick="setFilter('reviewing')">Reviewing</span>
                <span class="filter-chip ${currentFilter === 'resolved' ? 'active' : ''}" onclick="setFilter('resolved')">Resolved</span>
                <span class="filter-chip ${currentFilter === 'dismissed' ? 'active' : ''}" onclick="setFilter('dismissed')">Dismissed</span>
            </div>
        </div>
        
        <!-- Reports List -->
        <div class="reports-container">
            ${reports.length === 0 ? `
                <div class="empty-state">
                    <svg width="64" height="64" viewBox="0 0 24 24" fill="#999">
                        <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/>
                    </svg>
                    <h3>No reports found</h3>
                </div>
            ` : `
                <div class="reports-list">
                    ${reports.map(report => renderReportCard(report)).join('')}
                </div>
            `}
        </div>
    `;
}

function renderReportCard(report) {
    const statusColors = {
        pending: '#ff9800',
        reviewing: '#2196f3',
        resolved: '#4caf50',
        dismissed: '#f44336'
    };
    
    const reasonLabels = {
        inappropriate: 'Inappropriate Content',
        spam: 'Spam',
        misleading: 'Misleading',
        copyright: 'Copyright Violation',
        violence: 'Violence',
        hatespeech: 'Hate Speech',
        other: 'Other'
    };
    
    const color = statusColors[report.status] || '#999';
    const reasonLabel = reasonLabels[report.reason] || report.reason;
    const date = report.createdAt ? new Date(report.createdAt.toDate()).toLocaleString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }) : 'Unknown date';
    
    return `
        <div class="report-card" onclick="viewReportDetail('${report.id}')">
            <div class="report-header">
                <div class="report-badges">
                    <span class="badge badge-${report.status}">
                        ${report.status.toUpperCase()}
                    </span>
                    <span class="badge badge-reason">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M14.4 6L14 4H5v17h2v-7h5.6l.4 2h7V6z"/>
                        </svg>
                        ${reasonLabel}
                    </span>
                </div>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="#999">
                    <path d="M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"/>
                </svg>
            </div>
            <div class="report-title">${report.videoTitle || 'Untitled Video'}</div>
            <div class="report-meta">
                <div class="report-meta-item">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                    </svg>
                    Reported by: ${report.reporterEmail || 'Unknown'}
                </div>
                <div class="report-meta-item">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                    </svg>
                    Uploader: ${report.uploaderEmail || 'Unknown'}
                </div>
                <div class="report-meta-item">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z"/>
                    </svg>
                    ${date}
                </div>
            </div>
        </div>
    `;
}

// Bug Reports Page
function loadBugReports() {
    const stats = { pending: 0, investigating: 0, resolved: 0 };
    
    const unsubscribe = db.collection('bug_reports')
        .orderBy('createdAt', 'desc')
        .onSnapshot((snapshot) => {
            const allReports = [];
            snapshot.forEach(doc => {
                allReports.push({ id: doc.id, ...doc.data() });
            });
            
            stats.pending = allReports.filter(r => r.status === 'pending').length;
            stats.investigating = allReports.filter(r => r.status === 'investigating').length;
            stats.resolved = allReports.filter(r => r.status === 'resolved').length;
            
            const filteredReports = currentFilter === 'all' 
                ? allReports 
                : allReports.filter(r => r.status === currentFilter);
            
            renderBugReportsPage(stats, filteredReports);
        });
    
    unsubscribeListeners.push(unsubscribe);
}

function renderBugReportsPage(stats, reports) {
    contentArea.innerHTML = `
        <div class="stats-grid">
            <div class="stat-card" style="border-color: #ff9800;" onclick="setFilter('pending')">
                <div class="stat-card-header">
                    <div class="stat-icon" style="background: rgba(255, 152, 0, 0.1);">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="#ff9800">
                            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                        </svg>
                    </div>
                    <div class="stat-count" style="color: #ff9800;">${stats.pending}</div>
                </div>
                <div class="stat-title">Pending</div>
            </div>
            
            <div class="stat-card" style="border-color: #2196f3;" onclick="setFilter('investigating')">
                <div class="stat-card-header">
                    <div class="stat-icon" style="background: rgba(33, 150, 243, 0.1);">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="#2196f3">
                            <path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/>
                        </svg>
                    </div>
                    <div class="stat-count" style="color: #2196f3;">${stats.investigating}</div>
                </div>
                <div class="stat-title">Investigating</div>
            </div>
            
            <div class="stat-card" style="border-color: #4caf50;" onclick="setFilter('resolved')">
                <div class="stat-card-header">
                    <div class="stat-icon" style="background: rgba(76, 175, 80, 0.1);">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="#4caf50">
                            <path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/>
                        </svg>
                    </div>
                    <div class="stat-count" style="color: #4caf50;">${stats.resolved}</div>
                </div>
                <div class="stat-title">Resolved</div>
            </div>
        </div>
        
        <div class="filter-section">
            <div class="filter-title">Filter by Status</div>
            <div class="filter-chips">
                <span class="filter-chip ${currentFilter === 'all' ? 'active' : ''}" onclick="setFilter('all')">All Reports</span>
                <span class="filter-chip ${currentFilter === 'pending' ? 'active' : ''}" onclick="setFilter('pending')">Pending</span>
                <span class="filter-chip ${currentFilter === 'investigating' ? 'active' : ''}" onclick="setFilter('investigating')">Investigating</span>
                <span class="filter-chip ${currentFilter === 'resolved' ? 'active' : ''}" onclick="setFilter('resolved')">Resolved</span>
            </div>
        </div>
        
        <div class="reports-container">
            ${reports.length === 0 ? `
                <div class="empty-state">
                    <svg width="64" height="64" viewBox="0 0 24 24" fill="#999">
                        <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/>
                    </svg>
                    <h3>No bug reports found</h3>
                </div>
            ` : `
                <div class="reports-list">
                    ${reports.map(report => renderBugReportCard(report)).join('')}
                </div>
            `}
        </div>
    `;
}

function renderBugReportCard(report) {
    const statusColors = {
        pending: '#ff9800',
        investigating: '#2196f3',
        resolved: '#4caf50'
    };
    
    const color = statusColors[report.status] || '#999';
    const date = report.createdAt ? new Date(report.createdAt.toDate()).toLocaleString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }) : 'Unknown date';
    
    return `
        <div class="report-card" style="border-color: ${color}; border-width: 2px;">
            <div class="report-header">
                <div class="report-badges">
                    <span class="badge" style="background: ${color}20; color: ${color}; border: 1.5px solid ${color};">
                        ${report.status.toUpperCase()}
                    </span>
                </div>
            </div>
            <div class="report-title">${report.userName || 'Anonymous'}</div>
            <div class="report-meta">
                <div class="report-meta-item">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
                    </svg>
                    ${report.userEmail || 'No email'}
                </div>
            </div>
            <div style="margin-top: 12px; padding: 12px; background: #ffebee; border-radius: 8px; border: 1px solid #ffcdd2;">
                <div style="font-size: 12px; font-weight: bold; color: #666; margin-bottom: 8px;">Bug Description:</div>
                <div style="font-size: 14px; line-height: 1.5;">${report.description || 'No description'}</div>
            </div>
            ${report.adminNotes ? `
                <div style="margin-top: 12px; padding: 12px; background: #e3f2fd; border-radius: 8px;">
                    <div style="font-size: 12px; font-weight: bold; color: #666; margin-bottom: 8px;">Admin Notes:</div>
                    <div style="font-size: 14px; line-height: 1.5;">${report.adminNotes}</div>
                </div>
            ` : ''}
            <div style="margin-top: 16px; display: flex; justify-content: space-between; align-items: center;">
                <div class="report-meta-item">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z"/>
                    </svg>
                    ${date}
                </div>
                ${report.status !== 'resolved' ? `
                    <button class="btn btn-primary" style="padding: 6px 12px; font-size: 13px;" onclick="updateBugStatus('${report.id}', '${report.status}')">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/>
                        </svg>
                        Update Status
                    </button>
                ` : ''}
            </div>
        </div>
    `;
}

// User Feedback Page
function loadUserFeedback() {
    const stats = { pending: 0, reviewed: 0, resolved: 0 };
    
    const unsubscribe = db.collection('user_feedback')
        .orderBy('createdAt', 'desc')
        .onSnapshot((snapshot) => {
            const allFeedback = [];
            snapshot.forEach(doc => {
                allFeedback.push({ id: doc.id, ...doc.data() });
            });
            
            stats.pending = allFeedback.filter(f => f.status === 'pending').length;
            stats.reviewed = allFeedback.filter(f => f.status === 'reviewed').length;
            stats.resolved = allFeedback.filter(f => f.status === 'resolved').length;
            
            const filteredFeedback = currentFilter === 'all' 
                ? allFeedback 
                : allFeedback.filter(f => f.status === currentFilter);
            
            renderUserFeedbackPage(stats, filteredFeedback);
        });
    
    unsubscribeListeners.push(unsubscribe);
}

function renderUserFeedbackPage(stats, feedback) {
    contentArea.innerHTML = `
        <div class="stats-grid">
            <div class="stat-card" style="border-color: #ff9800;" onclick="setFilter('pending')">
                <div class="stat-card-header">
                    <div class="stat-icon" style="background: rgba(255, 152, 0, 0.1);">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="#ff9800">
                            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                        </svg>
                    </div>
                    <div class="stat-count" style="color: #ff9800;">${stats.pending}</div>
                </div>
                <div class="stat-title">Pending</div>
            </div>
            
            <div class="stat-card" style="border-color: #2196f3;" onclick="setFilter('reviewed')">
                <div class="stat-card-header">
                    <div class="stat-icon" style="background: rgba(33, 150, 243, 0.1);">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="#2196f3">
                            <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"/>
                        </svg>
                    </div>
                    <div class="stat-count" style="color: #2196f3;">${stats.reviewed}</div>
                </div>
                <div class="stat-title">Reviewed</div>
            </div>
            
            <div class="stat-card" style="border-color: #4caf50;" onclick="setFilter('resolved')">
                <div class="stat-card-header">
                    <div class="stat-icon" style="background: rgba(76, 175, 80, 0.1);">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="#4caf50">
                            <path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/>
                        </svg>
                    </div>
                    <div class="stat-count" style="color: #4caf50;">${stats.resolved}</div>
                </div>
                <div class="stat-title">Resolved</div>
            </div>
        </div>
        
        <div class="filter-section">
            <div class="filter-title">Filter by Status</div>
            <div class="filter-chips">
                <span class="filter-chip ${currentFilter === 'all' ? 'active' : ''}" onclick="setFilter('all')">All Feedback</span>
                <span class="filter-chip ${currentFilter === 'pending' ? 'active' : ''}" onclick="setFilter('pending')">Pending</span>
                <span class="filter-chip ${currentFilter === 'reviewed' ? 'active' : ''}" onclick="setFilter('reviewed')">Reviewed</span>
                <span class="filter-chip ${currentFilter === 'resolved' ? 'active' : ''}" onclick="setFilter('resolved')">Resolved</span>
            </div>
        </div>
        
        <div class="reports-container">
            ${feedback.length === 0 ? `
                <div class="empty-state">
                    <svg width="64" height="64" viewBox="0 0 24 24" fill="#999">
                        <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/>
                    </svg>
                    <h3>No feedback found</h3>
                </div>
            ` : `
                <div class="reports-list">
                    ${feedback.map(f => renderFeedbackCard(f)).join('')}
                </div>
            `}
        </div>
    `;
}

function renderFeedbackCard(feedback) {
    const statusColors = {
        pending: '#ff9800',
        reviewed: '#2196f3',
        resolved: '#4caf50'
    };
    
    const color = statusColors[feedback.status] || '#999';
    const date = feedback.createdAt ? new Date(feedback.createdAt.toDate()).toLocaleString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }) : 'Unknown date';
    
    return `
        <div class="report-card" style="border-color: ${color};">
            <div class="report-header">
                <div class="report-badges">
                    <span class="badge" style="background: ${color}20; color: ${color}; border: 1px solid ${color};">
                        ${feedback.status.toUpperCase()}
                    </span>
                </div>
            </div>
            <div class="report-title">${feedback.userName || 'Anonymous'}</div>
            <div class="report-meta">
                <div class="report-meta-item">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
                    </svg>
                    ${feedback.userEmail || 'No email'}
                </div>
            </div>
            <div style="margin-top: 12px; padding: 12px; background: #f5f5f5; border-radius: 8px;">
                <div style="font-size: 12px; font-weight: bold; color: #666; margin-bottom: 8px;">Feedback:</div>
                <div style="font-size: 14px; line-height: 1.5;">${feedback.feedback || 'No feedback'}</div>
            </div>
            ${feedback.adminNotes ? `
                <div style="margin-top: 12px; padding: 12px; background: #e3f2fd; border-radius: 8px;">
                    <div style="font-size: 12px; font-weight: bold; color: #666; margin-bottom: 8px;">Admin Notes:</div>
                    <div style="font-size: 14px; line-height: 1.5;">${feedback.adminNotes}</div>
                </div>
            ` : ''}
            <div style="margin-top: 16px; display: flex; justify-content: space-between; align-items: center;">
                <div class="report-meta-item">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z"/>
                    </svg>
                    ${date}
                </div>
                ${feedback.status !== 'resolved' ? `
                    <button class="btn btn-primary" style="padding: 6px 12px; font-size: 13px;" onclick="updateFeedbackStatus('${feedback.id}', '${feedback.status}')">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/>
                        </svg>
                        Update Status
                    </button>
                ` : ''}
            </div>
        </div>
    `;
}

// User Management Page
function loadUserManagement() {
    let searchQuery = '';
    let statusFilter = 'all';
    
    const renderSearch = () => {
        return `
            <div class="search-container">
                <input 
                    type="text" 
                    class="search-input" 
                    id="userSearch" 
                    placeholder="Search by name or email..."
                    value="${searchQuery}"
                >
                <div style="margin-top: 16px;">
                    <div class="filter-chips">
                        <span class="filter-chip ${statusFilter === 'all' ? 'active' : ''}" onclick="setUserFilter('all')">All Users</span>
                        <span class="filter-chip ${statusFilter === 'active' ? 'active' : ''}" onclick="setUserFilter('active')">Active</span>
                        <span class="filter-chip ${statusFilter === 'suspended' ? 'active' : ''}" onclick="setUserFilter('suspended')">Suspended</span>
                        <span class="filter-chip ${statusFilter === 'deleted' ? 'active' : ''}" onclick="setUserFilter('deleted')">Deleted</span>
                    </div>
                </div>
            </div>
        `;
    };
    
    const loadUsers = () => {
        let query = db.collection('users').orderBy('createdAt', 'desc');
        
        if (statusFilter === 'suspended') {
            query = query.where('isSuspended', '==', true);
        } else if (statusFilter === 'deleted') {
            query = query.where('isDeleted', '==', true);
        }
        
        const unsubscribe = query.onSnapshot((snapshot) => {
            const allUsers = [];
            snapshot.forEach(doc => {
                allUsers.push({ id: doc.id, ...doc.data() });
            });
            
            // Apply search filter
            const filteredUsers = searchQuery 
                ? allUsers.filter(u => {
                    const name = (u.displayName || '').toLowerCase();
                    const email = (u.email || '').toLowerCase();
                    return name.includes(searchQuery.toLowerCase()) || email.includes(searchQuery.toLowerCase());
                })
                : allUsers;
            
            renderUsers(filteredUsers);
        });
        
        unsubscribeListeners.push(unsubscribe);
    };
    
    const renderUsers = (users) => {
        contentArea.innerHTML = renderSearch() + `
            <div class="users-grid">
                ${users.length === 0 ? `
                    <div class="empty-state">
                        <svg width="64" height="64" viewBox="0 0 24 24" fill="#999">
                            <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                        </svg>
                        <h3>No users found</h3>
                    </div>
                ` : users.map(user => renderUserCard(user)).join('')}
            </div>
        `;
        
        // Attach search event listener
        const searchInput = document.getElementById('userSearch');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                searchQuery = e.target.value;
                loadUsers();
            });
        }
    };
    
    window.setUserFilter = (filter) => {
        statusFilter = filter;
        loadUsers();
    };
    
    loadUsers();
}

function renderUserCard(user) {
    const isSuspended = user.isSuspended || false;
    const isDeleted = user.isDeleted || false;
    const date = user.createdAt ? new Date(user.createdAt.toDate()).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
    }) : 'Unknown date';
    
    const initial = (user.displayName || 'U')[0].toUpperCase();
    
    return `
        <div class="user-card">
            <div class="user-header">
                <div class="user-avatar">
                    ${user.avatarUrl ? `<img src="${user.avatarUrl}" alt="${user.displayName}">` : initial}
                </div>
                <div class="user-info">
                    <div class="user-name">
                        ${user.displayName || 'Unknown User'}
                        ${isSuspended ? '<span class="user-status-badge suspended">SUSPENDED</span>' : ''}
                        ${isDeleted ? '<span class="user-status-badge deleted">DELETED</span>' : ''}
                    </div>
                    <div class="user-email">${user.email || 'No email'}</div>
                    <div class="user-joined">Joined: ${date}</div>
                </div>
            </div>
            
            <div class="user-actions">
                ${!isDeleted && !isSuspended ? `
                    <button class="btn btn-warning btn-outline" onclick="suspendUser('${user.id}', '${user.displayName}', '${user.email}')">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zM4 12c0-4.42 3.58-8 8-8 1.85 0 3.55.63 4.9 1.69L5.69 16.9C4.63 15.55 4 13.85 4 12zm8 8c-1.85 0-3.55-.63-4.9-1.69L18.31 7.1C19.37 8.45 20 10.15 20 12c0 4.42-3.58 8-8 8z"/>
                        </svg>
                        Suspend
                    </button>
                ` : ''}
                
                ${isSuspended && !isDeleted ? `
                    <button class="btn btn-success" onclick="unsuspendUser('${user.id}', '${user.displayName}')">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/>
                        </svg>
                        Unsuspend
                    </button>
                ` : ''}
                
                ${!isDeleted ? `
                    <button class="btn btn-danger btn-outline" onclick="deleteUser('${user.id}', '${user.displayName}', '${user.email}')">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/>
                        </svg>
                        Delete
                    </button>
                ` : ''}
                
                ${isDeleted ? `
                    <button class="btn btn-primary" onclick="restoreUser('${user.id}', '${user.displayName}')">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M13 3c-4.97 0-9 4.03-9 9H1l3.89 3.89.07.14L9 12H6c0-3.87 3.13-7 7-7s7 3.13 7 7-3.13 7-7 7c-1.93 0-3.68-.79-4.94-2.06l-1.42 1.42C8.27 19.99 10.51 21 13 21c4.97 0 9-4.03 9-9s-4.03-9-9-9z"/>
                        </svg>
                        Restore
                    </button>
                ` : ''}
            </div>
            
            ${(isSuspended || isDeleted) && (user.suspensionReason || user.deletionReason) ? `
                <div style="margin-top: 12px; padding: 12px; background: ${isSuspended ? '#fff3e0' : '#ffebee'}; border-radius: 8px; border: 1px solid ${isSuspended ? '#ffe0b2' : '#ffcdd2'};">
                    <div style="font-size: 12px; font-weight: bold; margin-bottom: 4px;">${isSuspended ? 'Suspension' : 'Deletion'} Info</div>
                    <div style="font-size: 12px;">Reason: ${user.suspensionReason || user.deletionReason}</div>
                </div>
            ` : ''}
        </div>
    `;
}

// User Management Actions and Status Updates
// All modal-based functions (suspendUser, unsuspendUser, deleteUser, restoreUser, 
// updateBugStatus, updateFeedbackStatus) are now defined in admin-modals.js

// View Report Detail
async function viewReportDetail(reportId) {
    showLoading();
    try {
        const reportDoc = await db.collection('video_reports').doc(reportId).get();
        if (!reportDoc.exists) {
            alert('Report not found');
            hideLoading();
            return;
        }
        
        const reportData = reportDoc.data();
        const videoId = reportData.videoId;
        
        // Check if video is deleted
        let isVideoDeleted = false;
        if (videoId) {
            const videoDoc = await db.collection('videos').doc(videoId).get();
            if (videoDoc.exists) {
                isVideoDeleted = videoDoc.data().isDeleted || false;
            }
        }
        
        hideLoading();
        showReportDetailModal(reportId, reportData, isVideoDeleted);
    } catch (error) {
        hideLoading();
        alert('Error loading report: ' + error.message);
    }
}

function showReportDetailModal(reportId, reportData, isVideoDeleted) {
    const status = reportData.status || 'pending';
    const reason = reportData.reason || 'other';
    const videoTitle = reportData.videoTitle || 'Untitled Video';
    const reporterEmail = reportData.reporterEmail || 'Unknown';
    const uploaderEmail = reportData.uploaderEmail || 'Unknown';
    const uploaderId = reportData.uploaderId || '';
    const videoUrl = reportData.videoUrl || '';
    const description = reportData.description || '';
    
    const date = reportData.createdAt ? new Date(reportData.createdAt.toDate()).toLocaleString('en-US', {
        month: 'long',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }) : 'Unknown date';
    
    const reasonLabels = {
        inappropriate: 'Inappropriate Content',
        spam: 'Spam',
        misleading: 'Misleading',
        copyright: 'Copyright Violation',
        violence: 'Violence',
        hatespeech: 'Hate Speech',
        other: 'Other'
    };
    
    const statusColors = {
        pending: '#ff9800',
        reviewing: '#2196f3',
        resolved: '#4caf50',
        dismissed: '#f44336'
    };
    
    const modalHtml = `
        <div class="modal-overlay" id="reportDetailModal" onclick="closeReportDetail(event)">
            <div class="modal" style="max-width: 900px; max-height: 95vh;" onclick="event.stopPropagation()">
                <div class="modal-header">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="#f44336">
                        <path d="M14.4 6L14 4H5v17h2v-7h5.6l.4 2h7V6z"/>
                    </svg>
                    <div class="modal-title">Report Details</div>
                    <button class="icon-button" onclick="closeReportDetail()">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                        </svg>
                    </button>
                </div>
                <div class="modal-body" style="max-height: calc(95vh - 180px); overflow-y: auto;">
                    ${videoUrl ? `
                        <div style="margin-bottom: 20px;">
                            <video id="reportVideo" controls style="width: 100%; max-height: 400px; background: #000; border-radius: 12px;">
                                <source src="${videoUrl}" type="video/mp4">
                                Your browser does not support the video tag.
                            </video>
                            <div style="margin-top: 8px; text-align: center;">
                                <button class="btn btn-outline" onclick="window.open('${videoUrl}', '_blank')" style="font-size: 12px; padding: 6px 12px;">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                                        <path d="M19 19H5V5h7V3H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2v-7h-2v7zM14 3v2h3.59l-9.83 9.83 1.41 1.41L19 6.41V10h2V3h-7z"/>
                                    </svg>
                                    Open Video Externally
                                </button>
                            </div>
                        </div>
                    ` : ''}
                    
                    <div style="background: white; padding: 20px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); margin-bottom: 20px;">
                        <h3 style="margin-bottom: 16px; font-size: 18px;">Report Information</h3>
                        <div style="border-top: 1px solid #eee; padding-top: 16px;">
                            <div class="info-row">
                                <strong style="width: 140px; display: inline-block; color: #666;">Status:</strong>
                                <span style="color: ${statusColors[status]}; font-weight: bold;">${status.toUpperCase()}</span>
                            </div>
                            <div class="info-row">
                                <strong style="width: 140px; display: inline-block; color: #666;">Reason:</strong>
                                <span>${reasonLabels[reason] || reason}</span>
                            </div>
                            <div class="info-row">
                                <strong style="width: 140px; display: inline-block; color: #666;">Video Title:</strong>
                                <span>${videoTitle}</span>
                            </div>
                            <div class="info-row">
                                <strong style="width: 140px; display: inline-block; color: #666;">Reported By:</strong>
                                <a href="#" onclick="closeReportDetail(); navigateToPage('user_management'); setTimeout(() => document.getElementById('userSearch').value = '${reporterEmail}'; document.getElementById('userSearch').dispatchEvent(new Event('input'));, 100); return false;" style="color: #2196f3; text-decoration: none;">
                                    ${reporterEmail} →
                                </a>
                            </div>
                            <div class="info-row">
                                <strong style="width: 140px; display: inline-block; color: #666;">Uploader:</strong>
                                <a href="#" onclick="closeReportDetail(); navigateToPage('user_management'); setTimeout(() => document.getElementById('userSearch').value = '${uploaderEmail}'; document.getElementById('userSearch').dispatchEvent(new Event('input'));, 100); return false;" style="color: #2196f3; text-decoration: none;">
                                    ${uploaderEmail} →
                                </a>
                            </div>
                            <div class="info-row">
                                <strong style="width: 140px; display: inline-block; color: #666;">Date Reported:</strong>
                                <span>${date}</span>
                            </div>
                            ${description ? `
                                <div style="margin-top: 16px;">
                                    <strong style="color: #666; display: block; margin-bottom: 8px;">Description:</strong>
                                    <div style="padding: 12px; background: #f5f5f5; border-radius: 8px; line-height: 1.6;">
                                        ${description}
                                    </div>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                    
                    ${isVideoDeleted ? `
                        <div style="background: #ffebee; border: 1px solid #ef5350; border-radius: 12px; padding: 16px; margin-bottom: 20px;">
                            <div style="display: flex; align-items: center; gap: 12px;">
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="#d32f2f">
                                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/>
                                </svg>
                                <strong style="color: #d32f2f;">This video has been deleted</strong>
                            </div>
                        </div>
                    ` : ''}
                    
                    <div style="background: white; padding: 20px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                        <h3 style="margin-bottom: 16px; font-size: 18px;">Admin Actions</h3>
                        <div style="display: flex; flex-wrap: wrap; gap: 12px;">
                            ${status !== 'reviewing' ? `
                                <button class="btn btn-primary" onclick="updateReportStatus('${reportId}', 'reviewing')">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                                        <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"/>
                                    </svg>
                                    Mark as Reviewing
                                </button>
                            ` : ''}
                            
                            <button class="btn btn-warning" onclick="sendWarningToUploader('${uploaderId}', '${reportId}', '${videoTitle}')">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/>
                                </svg>
                                Send Warning
                            </button>
                            
                            ${isVideoDeleted ? `
                                <button class="btn btn-success" onclick="restoreVideoFromReport('${reportData.videoId}', '${reportId}')">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                                        <path d="M13 3c-4.97 0-9 4.03-9 9H1l3.89 3.89.07.14L9 12H6c0-3.87 3.13-7 7-7s7 3.13 7 7-3.13 7-7 7c-1.93 0-3.68-.79-4.94-2.06l-1.42 1.42C8.27 19.99 10.51 21 13 21c4.97 0 9-4.03 9-9s-4.03-9-9-9z"/>
                                    </svg>
                                    Restore Video
                                </button>
                            ` : `
                                <button class="btn btn-danger" onclick="deleteVideoFromReport('${reportData.videoId}', '${reportId}')">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                                        <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/>
                                    </svg>
                                    Delete Video
                                </button>
                            `}
                            
                            ${status !== 'resolved' ? `
                                <button class="btn btn-success" onclick="updateReportStatus('${reportId}', 'resolved')">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                                        <path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/>
                                    </svg>
                                    Mark as Resolved
                                </button>
                            ` : ''}
                            
                            ${status !== 'dismissed' ? `
                                <button class="btn btn-outline btn-danger" onclick="updateReportStatus('${reportId}', 'dismissed')">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                                        <path d="M12 2C6.47 2 2 6.47 2 12s4.47 10 10 10 10-4.47 10-10S17.53 2 12 2zm5 13.59L15.59 17 12 13.41 8.41 17 7 15.59 10.59 12 7 8.41 8.41 7 12 10.59 15.59 7 17 8.41 13.41 12 17 15.59z"/>
                                    </svg>
                                    Dismiss Report
                                </button>
                            ` : ''}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', modalHtml);
}

function closeReportDetail(event) {
    if (event && event.target.id !== 'reportDetailModal') return;
    const modal = document.getElementById('reportDetailModal');
    if (modal) {
        modal.remove();
    }
}

// Report Actions
// Functions updateReportStatus, deleteVideoFromReport, restoreVideoFromReport, 
// and sendWarningToUploader are now defined in admin-modals.js

// Filter function
function setFilter(filter) {
    currentFilter = filter;
    loadPage(currentPage);
}

// Loading overlay
function showLoading() {
    loadingOverlay.style.display = 'flex';
}

function hideLoading() {
    loadingOverlay.style.display = 'none';
}

// Make functions globally accessible
window.setFilter = setFilter;
window.viewReportDetail = viewReportDetail;
window.updateReportStatus = updateReportStatus;
window.deleteVideoFromReport = deleteVideoFromReport;
window.restoreVideoFromReport = restoreVideoFromReport;
window.sendWarningToUploader = sendWarningToUploader;
window.closeReportDetail = closeReportDetail;
window.updateBugStatus = updateBugStatus;
window.updateFeedbackStatus = updateFeedbackStatus;
window.suspendUser = suspendUser;
window.unsuspendUser = unsuspendUser;
window.deleteUser = deleteUser;
window.restoreUser = restoreUser;
