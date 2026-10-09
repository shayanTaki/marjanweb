/* ============================================================
   Package Cards → Direct Buy Link
   ============================================================ */
(function() {
    'use strict';

    function ready(fn) {
        if (document.readyState !== 'loading') fn();
        else document.addEventListener('DOMContentLoaded', fn);
    }

    ready(function() {

        // Find all package cards
        const cards = document.querySelectorAll(
            '[data-package-card], .package-card, .pricing-card'
        );

        cards.forEach(function(card) {

            // Skip if already processed
            if (card.dataset.buyAttached === '1') return;
            card.dataset.buyAttached = '1';

            // Ensure cursor
            card.style.cursor = 'pointer';

            // Get buy URL
            var buyUrl = card.dataset.buyUrl;
            if (!buyUrl) {
                // Try finding a "buy" button inside
                var buyBtn = card.querySelector(
                    '.btn-buy, .buy-btn, [data-buy], a[href*="buy"], a[href*="checkout"], a[href*="purchase"]'
                );
                if (buyBtn) {
                    buyUrl = buyBtn.getAttribute('href');
                }
            }
            // Try data-slug
            if (!buyUrl) {
                var slug = card.dataset.packageSlug || card.dataset.slug;
                if (slug) buyUrl = '/packages/' + slug + '/buy/';
            }

            if (!buyUrl) return;

            // Add overlay link
            var overlay = document.createElement('a');
            overlay.href = buyUrl;
            overlay.className = 'card-overlay-link';
            overlay.setAttribute('aria-label', 'خرید بسته');
            overlay.textContent = 'خرید';
            overlay.style.cssText = 
                'position:absolute;inset:0;z-index:1;text-indent:-9999px;overflow:hidden;';

            // Only add if not already there
            if (!card.querySelector('.card-overlay-link')) {
                card.style.position = card.style.position || 'relative';
                card.appendChild(overlay);
            }

            // Make buttons clickable above overlay
            card.querySelectorAll('a, button, .btn-buy, .btn').forEach(function(el) {
                el.style.position = 'relative';
                el.style.zIndex = '2';
            });

            // Whole card click (fallback)
            card.addEventListener('click', function(e) {
                // If clicked on a link/button, let it handle
                if (e.target.closest('a, button')) return;
                // Otherwise go to buy page
                window.location.href = buyUrl;
            });

            // Keyboard accessibility
            card.setAttribute('tabindex', '0');
            card.setAttribute('role', 'link');
            card.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    window.location.href = buyUrl;
                }
            });
        });

        console.log('[Site] Package buy links attached:', cards.length);
    });
})();
