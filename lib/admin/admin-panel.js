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
    if (confirm('Are you sure you want to logout?')) {
        try {
            await auth.signOut();
        } catch (error) {
            alert('Logout error: ' + error.message);
        }
    }
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

// User Management Actions
async function suspendUser(userId, userName, userEmail) {
    const reason = prompt(`Suspend ${userName}?\n\nEnter suspension reason:`);
    if (!reason) return;
    
    const days = prompt('Suspension duration (days):', '7');
    if (!days) return;
    
    showLoading();
    try {
        const suspensionEndDate = new Date();
        suspensionEndDate.setDate(suspensionEndDate.getDate() + parseInt(days));
        
        await db.collection('users').doc(userId).update({
            isSuspended: true,
            suspensionReason: reason,
            suspendedAt: firebase.firestore.FieldValue.serverTimestamp(),
            suspendedBy: auth.currentUser.email,
            suspensionEndDate: firebase.firestore.Timestamp.fromDate(suspensionEndDate)
        });
        
        // Send notification
        await db.collection('count').doc(userId).collection('notifications').add({
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
        
        alert('User suspended successfully');
    } catch (error) {
        alert('Error suspending user: ' + error.message);
    }
    hideLoading();
}

async function unsuspendUser(userId, userName) {
    if (!confirm(`Remove suspension from ${userName}?`)) return;
    
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
        
        alert('User suspension removed');
    } catch (error) {
        alert('Error unsuspending user: ' + error.message);
    }
    hideLoading();
}

async function deleteUser(userId, userName, userEmail) {
    const reason = prompt(`Permanently delete ${userName}?\n\nEnter deletion reason:`);
    if (!reason) return;
    
    if (!confirm(`Are you sure you want to delete ${userName} (${userEmail})?`)) return;
    
    showLoading();
    try {
        await db.collection('users').doc(userId).update({
            isDeleted: true,
            deletionReason: reason,
            deletedAt: firebase.firestore.FieldValue.serverTimestamp(),
            deletedBy: auth.currentUser.email
        });
        
        // Hide all user's videos
        const videosSnapshot = await db.collection('videos')
            .where('uploaderId', '==', userId)
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
        
        await db.collection('count').doc(userId).collection('notifications').add({
            type: 'account_deletion',
            title: 'Account Deleted',
            message: `Your account has been deleted by admin. Reason: ${reason}`,
            fromUserId: auth.currentUser.uid,
            fromUserName: 'Admin',
            fromUserAvatar: '',
            isRead: false,
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        
        alert('User account deleted successfully');
    } catch (error) {
        alert('Error deleting user: ' + error.message);
    }
    hideLoading();
}

async function restoreUser(userId, userName) {
    if (!confirm(`Restore ${userName}'s account?`)) return;
    
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
        
        alert('User account restored');
    } catch (error) {
        alert('Error restoring user: ' + error.message);
    }
    hideLoading();
}

// Update Bug Status
async function updateBugStatus(bugId, currentStatus) {
    const statuses = ['pending', 'investigating', 'resolved'];
    const newStatus = prompt(`Current status: ${currentStatus}\n\nEnter new status (${statuses.join(', ')}):`);
    
    if (!newStatus || !statuses.includes(newStatus.toLowerCase())) {
        alert('Invalid status');
        return;
    }
    
    const notes = prompt('Admin notes (optional):');
    
    showLoading();
    try {
        const updateData = {
            status: newStatus.toLowerCase(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };
        
        if (notes) {
            updateData.adminNotes = notes;
        }
        
        await db.collection('bug_reports').doc(bugId).update(updateData);
        alert('Bug report status updated successfully');
    } catch (error) {
        alert('Error updating status: ' + error.message);
    }
    hideLoading();
}

// Update Feedback Status
async function updateFeedbackStatus(feedbackId, currentStatus) {
    const statuses = ['pending', 'reviewed', 'resolved'];
    const newStatus = prompt(`Current status: ${currentStatus}\n\nEnter new status (${statuses.join(', ')}):`);
    
    if (!newStatus || !statuses.includes(newStatus.toLowerCase())) {
        alert('Invalid status');
        return;
    }
    
    const notes = prompt('Admin notes (optional):');
    
    showLoading();
    try {
        const updateData = {
            status: newStatus.toLowerCase(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };
        
        if (notes) {
            updateData.adminNotes = notes;
        }
        
        await db.collection('user_feedback').doc(feedbackId).update(updateData);
        alert('Feedback status updated successfully');
    } catch (error) {
        alert('Error updating status: ' + error.message);
    }
    hideLoading();
}

// View Report Detail - Simplified for now, can be expanded
function viewReportDetail(reportId) {
    alert(`Viewing report ${reportId}\n\nThis would open a detailed view of the report with video player and admin actions.`);
    // In a full implementation, this would open a modal or new page with report details
}

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
window.updateBugStatus = updateBugStatus;
window.updateFeedbackStatus = updateFeedbackStatus;
window.suspendUser = suspendUser;
window.unsuspendUser = unsuspendUser;
window.deleteUser = deleteUser;
window.restoreUser = restoreUser;
