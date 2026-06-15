// Intersection Observer for scroll animations
document.addEventListener('DOMContentLoaded', () => {
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.1
    };

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                observer.unobserve(entry.target); // Only animate once
            }
        });
    }, observerOptions);

    const fadeElements = document.querySelectorAll('.fade-in');
    fadeElements.forEach(el => observer.observe(el));
});

// Copy code functionality
function copyCode(button) {
    const pre = button.parentElement.nextElementSibling;
    const code = pre.querySelector('code').innerText;
    
    navigator.clipboard.writeText(code).then(() => {
        const originalText = button.innerText;
        button.innerText = 'Copied!';
        button.style.color = 'var(--success)';
        button.style.borderColor = 'var(--success)';
        
        setTimeout(() => {
            button.innerText = originalText;
            button.style.color = '';
            button.style.borderColor = '';
        }, 2000);
    });
}

// Accordion functionality
document.addEventListener('DOMContentLoaded', () => {
    const accordions = document.querySelectorAll('.accordion-header');
    
    accordions.forEach(acc => {
        acc.addEventListener('click', function() {
            // Toggle active class on accordion container
            const accordionItem = this.parentElement;
            
            // Close other open accordions if you want exclusive open (optional)
            // document.querySelectorAll('.accordion.active').forEach(openAcc => {
            //     if (openAcc !== accordionItem) {
            //         openAcc.classList.remove('active');
            //         openAcc.querySelector('.accordion-content').style.maxHeight = null;
            //     }
            // });

            accordionItem.classList.toggle('active');
            
            const content = this.nextElementSibling;
            if (accordionItem.classList.contains('active')) {
                // Add an arbitrary large max-height or exact scrollHeight
                content.style.maxHeight = content.scrollHeight + 100 + "px";
            } else {
                content.style.maxHeight = null;
            }
        });
    });
});
