/**
 * Cloud CV - Clean Version
 */

class CloudCV {
    constructor() {
        this.apiUrl = 'https://ojuuinvipa.execute-api.us-east-1.amazonaws.com/prod/visitor-count';
        this.visitorCount = 0;
        this.init();
    }

    init() {
        this.loadVisitorCount();
    }

    async loadVisitorCount() {
        try {
            const response = await fetch(this.apiUrl, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
                mode: 'cors'
            });

            if (!response.ok) {
                throw new Error('HTTP error! status: ' + response.status);
            }

            const data = await response.json();
            
            if (data.status === 'success' && data.visitor_count !== undefined) {
                this.updateVisitorCount(data.visitor_count);
            } else {
                this.updateVisitorCount(0);
            }
        } catch (error) {
            console.error('Error loading visitor count:', error);
            this.updateVisitorCount(0);
        }
    }

    updateVisitorCount(count) {
        this.visitorCount = count;
        const countElement = document.getElementById('visitor-count');
        
        if (countElement) {
            countElement.textContent = count.toLocaleString();
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    new CloudCV();
});
