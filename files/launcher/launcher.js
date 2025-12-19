/**
 * Smart TV Launcher - JavaScript
 * Handles app launching and UI interactions
 */

// Update clock
function updateClock() {
    const clockElement = document.getElementById('clock');
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    clockElement.textContent = `${hours}:${minutes}`;
}

// Initialize clock
updateClock();
setInterval(updateClock, 1000);

/**
 * Launch an application
 * @param {string} appId - The application identifier
 */
function launchApp(appId) {
    console.log(`Launching app: ${appId}`);
    
    // Visual feedback
    const tiles = document.querySelectorAll('.tile');
    tiles.forEach(tile => {
        if (tile.onclick && tile.onclick.toString().includes(appId)) {
            tile.style.opacity = '0.5';
            setTimeout(() => {
                tile.style.opacity = '1';
            }, 200);
        }
    });
    
    // Navigate to appropriate URL
    switch (appId) {
        case 'youtube-tv':
            window.location.href = 'https://www.youtube.com/tv';
            break;
        case 'youtube-kids':
            window.location.href = 'https://www.youtubekids.com';
            break;
        case 'cineby':
            window.location.href = 'https://example.com'; // placeholder for Cineby
            break;
        case 'tv-browser':
            window.location.href = 'https://duckduckgo.com';
            break;
        case 'settings':
            // Reload launcher
            window.location.href = 'file://__LAUNCHER_INDEX_HTML__';
            break;
        default:
            console.log('Unknown appId:', appId);
    }
}

/**
 * Power off the system
 */
function powerOff() {
    console.log('Power off requested');
    
    const confirmed = confirm('Are you sure you want to power off?');
    
    if (confirmed) {
        console.log('Power off confirmed');
        // Close the window (or navigate away)
        window.close();
    }
}

/**
 * Keyboard navigation support
 */
document.addEventListener('keydown', (event) => {
    const tiles = Array.from(document.querySelectorAll('.tile'));
    const currentIndex = tiles.findIndex(tile => tile === document.activeElement);
    
    let newIndex = currentIndex;
    
    switch(event.key) {
        case 'ArrowRight':
            event.preventDefault();
            newIndex = Math.min(currentIndex + 1, tiles.length - 1);
            break;
        case 'ArrowLeft':
            event.preventDefault();
            newIndex = Math.max(currentIndex - 1, 0);
            break;
        case 'ArrowDown':
            event.preventDefault();
            newIndex = Math.min(currentIndex + 3, tiles.length - 1);
            break;
        case 'ArrowUp':
            event.preventDefault();
            newIndex = Math.max(currentIndex - 3, 0);
            break;
        case 'Enter':
            if (document.activeElement.classList.contains('tile')) {
                document.activeElement.click();
            }
            break;
        case 'Escape':
            // Optional: Add exit functionality later
            console.log('Escape pressed');
            break;
    }
    
    if (newIndex !== currentIndex && newIndex >= 0 && newIndex < tiles.length) {
        tiles[newIndex].focus();
    }
});

// Focus first tile on load
window.addEventListener('load', () => {
    const firstTile = document.querySelector('.tile');
    if (firstTile) {
        firstTile.focus();
    }
});

console.log('Smart TV Launcher initialized');
