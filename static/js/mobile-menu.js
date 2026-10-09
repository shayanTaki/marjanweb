/* ============================================================
   Mobile Menu - Vanilla JS (no dependencies)
   ============================================================ */
(function() {
    'use strict';

    function ready(fn) {
        if (document.readyState !== 'loading') fn();
        else document.addEventListener('DOMContentLoaded', fn);
    }

    ready(function() {
        var overlay = document.getElementById('mobileMenuOverlay');
        var openBtn = document.getElementById('mobileMenuOpenBtn');
        var closeBtn = document.getElementById('mobileMenuCloseBtn');
        var backdrop = document.getElementById('mobileMenuBackdrop');
        var panel = document.getElementById('mobileMenuPanel');

        if (!overlay || !openBtn) {
            console.log('[MobileMenu] Elements not found');
            return;
        }

        console.log('[MobileMenu] Initialized');

        function openMenu() {
            overlay.classList.add('is-open');
            document.body.classList.add('mobile-menu-is-open');
            console.log('[MobileMenu] Opened');
        }

        function closeMenu() {
            overlay.classList.remove('is-open');
            document.body.classList.remove('mobile-menu-is-open');
            console.log('[MobileMenu] Closed');
        }

        // Open button
        openBtn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            openMenu();
        });

        // Close button
        if (closeBtn) {
            closeBtn.addEventListener('click', function(e) {
                e.preventDefault();
                closeMenu();
            });
        }

        // Backdrop click
        if (backdrop) {
            backdrop.addEventListener('click', closeMenu);
        }

        // Escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && overlay.classList.contains('is-open')) {
                closeMenu();
            }
        });

        // Close when a link is clicked
        if (panel) {
            panel.querySelectorAll('a').forEach(function(link) {
                link.addEventListener('click', function() {
                    setTimeout(closeMenu, 100);
                });
            });
        }

        // Close on resize to desktop
        window.addEventListener('resize', function() {
            if (window.innerWidth >= 1024 && overlay.classList.contains('is-open')) {
                closeMenu();
            }
        });
    });
})();
