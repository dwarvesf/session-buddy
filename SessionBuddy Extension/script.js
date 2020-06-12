document.addEventListener("DOMContentLoaded", function(event) {
    if (window.top === window) {
        safari.extension.dispatchMessage("DOMContentLoaded");
    }
});


if (window.top === window) {
    window.onunload = function(event) {
          safari.extension.dispatchMessage("BeforeUnload");
    };
}
