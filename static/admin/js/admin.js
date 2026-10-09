(function($) {
    $(document).ready(function() {
        console.log('مرجان آرام - پنل مدیریت');
        
        // انتقال منو به بدنه در صورت نیاز
        var topNav = $('#top-nav, .top-nav');
        if (topNav.length) {
            $('body').append(topNav);
            console.log('[Admin] Moving top-nav to body');
        }

        // منطق باز و بسته کردن منو
        var menuToggle = $('.menu-toggle, #menu-toggle');
        var sidebar = $('.sidebar, #sidebar');

        if (menuToggle.length && sidebar.length) {
            menuToggle.on('click', function(e) {
                e.preventDefault();
                sidebar.toggleClass('open');
                console.log('[Admin] Menu toggled');
            });
        }

        console.log('[Admin] Menu initialized');
        console.log('[Admin] Setup complete');
    });
})(django.jQuery); // استفاده از jQuery اختصاصی جنگو برای جلوگیری از خطا
