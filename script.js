// Dynamic Cursor Tracking
document.addEventListener('DOMContentLoaded', () => {
    const cursorGlow = document.getElementById('cursor-glow');
    let isMouseMoving = false;
    let mouseX = 0;
    let mouseY = 0;

    // Follow cursor
    document.addEventListener('mousemove', (e) => {
        mouseX = e.clientX;
        mouseY = e.clientY;
        isMouseMoving = true;
    });

    function updateCursor() {
        if (isMouseMoving) {
            cursorGlow.style.opacity = '1';
            cursorGlow.style.transform = `translate(calc(${mouseX}px - 50%), calc(${mouseY}px - 50%)) translateZ(0)`;
        }
        requestAnimationFrame(updateCursor);
    }
    requestAnimationFrame(updateCursor);

    // Fade out when mouse stops
    setInterval(() => {
        if (!isMouseMoving) {
            cursorGlow.style.opacity = '0';
        }
        isMouseMoving = false;
    }, 1000);

    // Advanced Scroll Reveal (Intersection Observer)
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.15
    };

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    const fadeElements = document.querySelectorAll('.fade-up');
    fadeElements.forEach(el => observer.observe(el));

    // Terminal Boot Simulator
    startTerminalBoot();
});

// Copy Code Functionality
function copyCode(button) {
    const pre = button.parentElement.nextElementSibling;
    const code = pre.querySelector('code').innerText;
    
    navigator.clipboard.writeText(code).then(() => {
        const originalText = button.innerText;
        button.innerText = 'Copied!';
        button.style.color = 'var(--accent-emerald)';
        
        setTimeout(() => {
            button.innerText = originalText;
            button.style.color = '';
        }, 2000);
    }).catch(err => {
        console.error('Clipboard copy failed:', err);
        const originalText = button.innerText;
        button.innerText = 'Failed';
        button.style.color = '#ef4444';
        
        setTimeout(() => {
            button.innerText = originalText;
            button.style.color = '';
        }, 2000);
    });
}

// Terminal Simulator Logic
const terminalLines = [
    { text: 'pwsh -ExecutionPolicy Bypass -File "./sovereign.ps1"', class: 'term-prompt' },
    { text: '[SYSTEM] Initializing Master Controller...', class: 'term-sys', delay: 800 },
    { text: '[MUTEX] OS-Level Lock Acquired.', class: 'term-success', delay: 500 },
    { text: '[INTEGRITY] SHA256 validation passed.', class: 'term-success', delay: 400 },
    { text: '[EVOLUTION] Auto-fetching skill: browser-use', class: 'term-sys', delay: 1000 },
    { text: 'Mounting to .cloud-cache/browser-use...', class: 'term-secondary', delay: 400 },
    { text: '[SECURITY] AST Sweep: 0 vulnerabilities found.', class: 'term-success', delay: 800 },
    { text: '[SUCCESS] Sovereign v15.0.0-CloudNative ONLINE', class: 'term-success', delay: 600 }
];

async function startTerminalBoot() {
    const termBody = document.getElementById('typewriter');
    if (!termBody) return;

    for (let i = 0; i < terminalLines.length; i++) {
        const line = terminalLines[i];
        
        // Wait before showing the next line to simulate processing
        if (line.delay) await sleep(line.delay);

        const p = document.createElement('p');
        p.className = `term-line ${line.class}`;
        
        if (line.class === 'term-prompt') {
            p.innerHTML = `<span style="color:var(--text-secondary)">PS C:\\Skills></span> ${line.text}`;
        } else {
            p.innerText = line.text;
        }

        termBody.appendChild(p);
        termBody.scrollTop = termBody.scrollHeight; // Auto-scroll
    }

    // Add blinking cursor at the end
    const cursor = document.createElement('span');
    cursor.className = 'blinking-cursor';
    termBody.lastElementChild.appendChild(cursor);
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
