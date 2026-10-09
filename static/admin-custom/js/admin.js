/* ============================================================
   Admin JS - CLEAN v12
   ============================================================ */
'use strict';

window.__adminInitialized = true;
console.log('%c[Admin] Script loaded', 'color:#3B82F6;font-weight:bold;');

// ============================================================
//  jQuery Mock - Complete enough for Django admin
// ============================================================
(function setupJQueryMock() {
    if (typeof window.jQuery !== 'undefined' && window.jQuery.fn) return;

    function JQ(selector) {
        if (typeof selector === 'function') {
            if (document.readyState !== 'loading') {
                selector();
            } else {
                document.addEventListener('DOMContentLoaded', selector);
            }
            return null;
        }

        var nodes;
        if (typeof selector === 'string') {
            nodes = document.querySelectorAll(selector);
        } else if (selector instanceof Element || selector === document || selector === window) {
            nodes = [selector];
        } else if (selector instanceof NodeList) {
            nodes = selector;
        } else {
            nodes = [];
        }

        var obj = {
            length: nodes.length,
            0: nodes[0],
            each: function(fn) {
                Array.prototype.forEach.call(nodes, function(el, i) {
                    fn.call(el, i, el);
                });
                return obj;
            },
            data: function(key, value) {
                if (value !== undefined) {
                    Array.prototype.forEach.call(nodes, function(el) {
                        el.dataset[key] = value;
                    });
                    return obj;
                }
                if (nodes.length === 0) return undefined;
                if (key === undefined) return nodes[0].dataset;
                return nodes[0].dataset[key];
            },
            on: function(event, handler) {
                Array.prototype.forEach.call(nodes, function(el) {
                    el.addEventListener(event, handler);
                });
                return obj;
            },
            off: function(event, handler) {
                Array.prototype.forEach.call(nodes, function(el) {
                    el.removeEventListener(event, handler);
                });
                return obj;
            },
            find: function(sel) {
                return new JQ(nodes.length > 0 ? nodes[0].querySelectorAll(sel) : []);
            },
            addClass: function(cls) {
                Array.prototype.forEach.call(nodes, function(el) { el.classList.add(cls); });
                return obj;
            },
            removeClass: function(cls) {
                Array.prototype.forEach.call(nodes, function(el) { el.classList.remove(cls); });
                return obj;
            },
            toggleClass: function(cls) {
                Array.prototype.forEach.call(nodes, function(el) { el.classList.toggle(cls); });
                return obj;
            },
            attr: function(name, value) {
                if (value === undefined) {
                    return nodes.length > 0 ? nodes[0].getAttribute(name) : undefined;
                }
                Array.prototype.forEach.call(nodes, function(el) { el.setAttribute(name, value); });
                return obj;
            },
            val: function(value) {
                if (value === undefined) {
                    return nodes.length > 0 ? nodes[0].value : undefined;
                }
                Array.prototype.forEach.call(nodes, function(el) { el.value = value; });
                return obj;
            },
            html: function(html) {
                if (html === undefined) {
                    return nodes.length > 0 ? nodes[0].innerHTML : '';
                }
                Array.prototype.forEach.call(nodes, function(el) { el.innerHTML = html; });
                return obj;
            },
            text: function(text) {
                if (text === undefined) {
                    return nodes.length > 0 ? nodes[0].textContent : '';
                }
                Array.prototype.forEach.call(nodes, function(el) { el.textContent = text; });
                return obj;
            },
            append: function(el) {
                Array.prototype.forEach.call(nodes, function(target) {
                    if (typeof el === 'string') target.insertAdjacentHTML('beforeend', el);
                    else target.appendChild(el);
                });
                return obj;
            },
            css: function(prop, value) {
                if (typeof prop === 'object') {
                    Array.prototype.forEach.call(nodes, function(el) {
                        for (var k in prop) el.style[k] = prop[k];
                    });
                    return obj;
                }
                if (value === undefined) {
                    return nodes.length > 0 ? getComputedStyle(nodes[0])[prop] : '';
                }
                Array.prototype.forEach.call(nodes, function(el) { el.style[prop] = value; });
                return obj;
            },
            hide: function() {
                Array.prototype.forEach.call(nodes, function(el) { el.style.display = 'none'; });
                return obj;
            },
            show: function() {
                Array.prototype.forEach.call(nodes, function(el) { el.style.display = ''; });
                return obj;
            },
        };
        return obj;
    }

    JQ.fn = {};
    JQ.ajax = function() { return { done: function(){return this;}, fail: function(){return this;} }; };
    JQ.each = function(arr, fn) {
        if (Array.isArray(arr)) arr.forEach(fn);
        return arr;
    };
    JQ.extend = function(target) {
        for (var i = 1; i < arguments.length; i++) {
            for (var k in arguments[i]) target[k] = arguments[i][k];
        }
        return target;
    };
    JQ.data = function(el, key) {
        return el && el.dataset ? el.dataset[key] : undefined;
    };

    window.jQuery = JQ;
    window.$ = JQ;
    window.django = window.django || {};
    window.django.jQuery = JQ;
    console.log('[Admin] jQuery mock installed');
})();

// ============================================================
//  SCROLLBAR FIX - kill all except main
// ============================================================
(function fixScrollbar() {
    // Main scrollbar only on html
    var htmlStyle = document.createElement('style');
    htmlStyle.textContent = `
        html {
            overflow-y: scroll !important;
            overflow-x: hidden !important;
            height: 100%;
        }
        body {
            overflow: visible !important;
            overflow-x: hidden !important;
            min-height: 100%;
        }
        #container, #main, .main, main,
        .content, .main-content {
            overflow: visible !important;
            overflow-x: hidden !important;
        }
        /* Kill any horizontal scrollbar */
        ::-webkit-scrollbar:horizontal {
            display: none !important;
            height: 0 !important;
        }
        /* Nice vertical scrollbar */
        ::-webkit-scrollbar {
            width: 10px !important;
        }
        ::-webkit-scrollbar-track {
            background: #0A0E1F !important;
        }
        ::-webkit-scrollbar-thumb {
            background: #334155 !important;
            border-radius: 5px !important;
            border: 2px solid #0A0E1F !important;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: #475569 !important;
        }
    `;
    document.head.appendChild(htmlStyle);
})();

// ============================================================
//  MENU
// ============================================================
var menuOpen = false;

function openAdminMenu() {
    var btn = document.getElementById('adminMenuBtn');
    var panel = document.getElementById('adminMenuPanel');
    if (!btn || !panel) return;

    var rect = btn.getBoundingClientRect();
    var winW = window.innerWidth;
    var winH = window.innerHeight;

    if (winW <= 768) {
        // Mobile: bottom sheet
        panel.style.top = 'auto';
        panel.style.bottom = '12px';
        panel.style.left = '12px';
        panel.style.right = '12px';
        panel.style.width = 'auto';
        panel.style.maxHeight = '75vh';
    } else {
        // Desktop: 360px wide, aligned to right edge of button
        var menuWidth = 360;
        var rightOffset = winW - rect.right;

        // Keep within bounds
        if (rightOffset + menuWidth > winW - 20) {
            rightOffset = 20;
        }

        panel.style.top = (rect.bottom + 8) + 'px';
        panel.style.bottom = 'auto';
        panel.style.right = Math.max(20, rightOffset) + 'px';
        panel.style.left = 'auto';
        panel.style.width = menuWidth + 'px';
        panel.style.maxHeight = Math.max(300, winH - rect.bottom - 30) + 'px';
    }

    panel.classList.add('is-open');
    btn.classList.add('top-nav-btn-active');
    menuOpen = true;
}

function closeAdminMenu() {
    var btn = document.getElementById('adminMenuBtn');
    var panel = document.getElementById('adminMenuPanel');
    if (panel) panel.classList.remove('is-open');
    if (btn) btn.classList.remove('top-nav-btn-active');
    menuOpen = false;
}

document.addEventListener('click', function(e) {
    var btn = e.target.closest ? e.target.closest('#adminMenuBtn') : null;
    if (btn) {
        e.preventDefault();
        e.stopPropagation();
        menuOpen ? closeAdminMenu() : openAdminMenu();
        return;
    }

    var panel = e.target.closest ? e.target.closest('#adminMenuPanel') : null;
    if (panel) {
        var link = e.target.closest ? e.target.closest('a') : null;
        if (link) setTimeout(closeAdminMenu, 150);
        e.stopPropagation();
        return;
    }

    if (menuOpen) closeAdminMenu();
}, true);

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && menuOpen) closeAdminMenu();
});

window.addEventListener('resize', function() {
    if (menuOpen) { closeAdminMenu(); setTimeout(openAdminMenu, 10); }
});

// ============================================================
//  PAGE SETUP
// ============================================================
function setupPage() {
    var topNav = document.getElementById('topNav');
    if (topNav && topNav.parentElement !== document.body) {
        document.body.insertBefore(topNav, document.body.firstChild);
    }
    if (topNav) document.body.classList.add('has-top-nav');

    var path = window.location.pathname;
    if (path.indexOf('/login') !== -1) document.body.classList.add('login');
    if (window.location.search.indexOf('_popup=1') !== -1) document.body.classList.add('popup');
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupPage);
} else {
    setupPage();
}
window.addEventListener('load', setupPage);

// Delete confirm
document.addEventListener('click', function(e) {
    var del = e.target.closest ? e.target.closest('a.deletelink') : null;
    if (del && !confirm('آیا از حذف این آیتم مطمئن هستید؟')) {
        e.preventDefault();
    }
});

console.log('[Admin] Setup complete');
