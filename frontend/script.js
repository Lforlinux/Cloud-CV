/**
 * Cloud CV - Interactive Resume JavaScript
 * SRE/DevOps Engineer Portfolio
 */

class CloudCV {
    constructor() {
        this.apiUrl = 'http://localhost:4566/restapis/zjx4hrjh1z/prod/_user_request_/visitor-count'; // LocalStack API endpoint
        this.visitorCount = 0;
        this.init();
    }

    /**
     * Initialize the application
     */
    init() {
        this.setupEventListeners();
        this.loadVisitorCount();
        this.setupAnimations();
        this.setupIntersectionObserver();
    }

    /**
     * Setup event listeners
     */
    setupEventListeners() {
        // Smooth scrolling for anchor links
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', (e) => {
                e.preventDefault();
                const target = document.querySelector(anchor.getAttribute('href'));
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            });
        });

        // Add click tracking for external links
        document.querySelectorAll('a[target="_blank"]').forEach(link => {
            link.addEventListener('click', () => {
                this.trackEvent('external_link_click', {
                    url: link.href,
                    text: link.textContent.trim()
                });
            });
        });

        // Add hover effects to skill tags
        document.querySelectorAll('.skill-tag').forEach(tag => {
            tag.addEventListener('mouseenter', () => {
                tag.style.transform = 'scale(1.1)';
                tag.style.boxShadow = '0 4px 12px rgba(79, 70, 229, 0.3)';
            });
            
            tag.addEventListener('mouseleave', () => {
                tag.style.transform = 'scale(1)';
                tag.style.boxShadow = 'none';
            });
        });

        // Add hover effects to experience items
        document.querySelectorAll('.experience-item').forEach(item => {
            item.addEventListener('mouseenter', () => {
                item.style.transform = 'translateX(10px)';
                item.style.boxShadow = '0 10px 25px rgba(0, 0, 0, 0.15)';
            });
            
            item.addEventListener('mouseleave', () => {
                item.style.transform = 'translateX(0)';
                item.style.boxShadow = '0 5px 15px rgba(0, 0, 0, 0.08)';
            });
        });
    }

    /**
     * Load visitor count from API
     */
    async loadVisitorCount() {
        try {
            // Use LocalStack API endpoint directly
            const apiUrl = this.apiUrl;
            
            if (!apiUrl) {
                console.log('API URL not configured, using mock data');
                this.updateVisitorCount(1234); // Mock data
                return;
            }

            const response = await fetch(apiUrl, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
                mode: 'cors'
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            
            if (data.visitor_count !== undefined) {
                this.updateVisitorCount(data.visitor_count);
            } else {
                throw new Error('Invalid response format');
            }
        } catch (error) {
            console.error('Error loading visitor count:', error);
            this.updateVisitorCount(0);
            
            // Track error
            this.trackEvent('visitor_count_error', {
                error: error.message
            });
        }
    }

    /**
     * Get API URL from environment or configuration
     */
    getApiUrl() {
        // Check for API URL in meta tag or environment
        const metaApiUrl = document.querySelector('meta[name="api-url"]');
        if (metaApiUrl) {
            return metaApiUrl.getAttribute('content');
        }

        // Check for global variable
        if (window.API_URL) {
            return window.API_URL;
        }

        // Check for environment variable (if using build tools)
        if (process && process.env && process.env.API_URL) {
            return process.env.API_URL;
        }

        return null;
    }

    /**
     * Update visitor count display
     */
    updateVisitorCount(count) {
        this.visitorCount = count;
        const countElement = document.getElementById('visitor-count');
        
        if (countElement) {
            // Animate the number change
            this.animateNumber(countElement, 0, count, 1000);
        }
    }

    /**
     * Animate number change
     */
    animateNumber(element, start, end, duration) {
        const startTime = performance.now();
        
        const animate = (currentTime) => {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            // Easing function (ease-out)
            const easeOut = 1 - Math.pow(1 - progress, 3);
            const current = Math.floor(start + (end - start) * easeOut);
            
            element.textContent = current.toLocaleString();
            
            if (progress < 1) {
                requestAnimationFrame(animate);
            }
        };
        
        requestAnimationFrame(animate);
    }

    /**
     * Setup animations
     */
    setupAnimations() {
        // Add loading animation to visitor count
        const countElement = document.getElementById('visitor-count');
        if (countElement) {
            countElement.classList.add('loading');
        }

        // Add fade-in animation to sections
        const sections = document.querySelectorAll('.section');
        sections.forEach((section, index) => {
            section.style.opacity = '0';
            section.style.transform = 'translateY(20px)';
            section.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
            
            setTimeout(() => {
                section.style.opacity = '1';
                section.style.transform = 'translateY(0)';
            }, index * 200);
        });
    }

    /**
     * Setup intersection observer for scroll animations
     */
    setupIntersectionObserver() {
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('fade-in');
                }
            });
        }, observerOptions);

        // Observe all sections
        document.querySelectorAll('.section').forEach(section => {
            observer.observe(section);
        });
    }

    /**
     * Track events (for analytics)
     */
    trackEvent(eventName, eventData) {
        console.log(`Event: ${eventName}`, eventData);
        
        // You can integrate with Google Analytics or other tracking services here
        if (typeof gtag !== 'undefined') {
            gtag('event', eventName, eventData);
        }
    }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new CloudCV();
});

// Add some additional interactive features
document.addEventListener('DOMContentLoaded', () => {
    // Add smooth scrolling to all internal links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Add hover effects to skill tags
    document.querySelectorAll('.skill-tag').forEach(tag => {
        tag.addEventListener('mouseenter', function() {
            this.style.transform = 'scale(1.1)';
            this.style.boxShadow = '0 4px 12px rgba(79, 70, 229, 0.3)';
            this.style.transition = 'all 0.2s ease';
        });
        
        tag.addEventListener('mouseleave', function() {
            this.style.transform = 'scale(1)';
            this.style.boxShadow = 'none';
        });
    });

    // Add click effects to buttons
    document.querySelectorAll('.footer-links a').forEach(button => {
        button.addEventListener('click', function() {
            this.style.transform = 'scale(0.95)';
            setTimeout(() => {
                this.style.transform = 'scale(1)';
            }, 150);
        });
    });

    // Add typing effect to the name
    const nameElement = document.querySelector('.name');
    if (nameElement) {
        const originalText = nameElement.textContent;
        nameElement.textContent = '';
        
        let i = 0;
        const typeWriter = () => {
            if (i < originalText.length) {
                nameElement.textContent += originalText.charAt(i);
                i++;
                setTimeout(typeWriter, 100);
            }
        };
        
        setTimeout(typeWriter, 500);
    }
});

// Add some CSS animations via JavaScript
document.addEventListener('DOMContentLoaded', () => {
    // Add staggered animation to layout items
    const layoutItems = document.querySelectorAll('.section');
    layoutItems.forEach((item, index) => {
        item.style.opacity = '0';
        item.style.transform = 'translateY(30px)';
        item.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        
        setTimeout(() => {
            item.style.opacity = '1';
            item.style.transform = 'translateY(0)';
        }, index * 150);
    });

    // Add hover effects to links
    document.querySelectorAll('a').forEach(link => {
        link.addEventListener('mouseenter', function() {
            this.style.color = '#7C3AED';
            this.style.transition = 'color 0.2s ease';
        });
        
        link.addEventListener('mouseleave', function() {
            this.style.color = '#4F46E5';
        });
    });

    // Add parallax effect to header
    window.addEventListener('scroll', () => {
        const scrolled = window.pageYOffset;
        const header = document.querySelector('.header');
        if (header) {
            header.style.transform = `translateY(${scrolled * 0.5}px)`;
        }
    });
});