document.addEventListener("DOMContentLoaded", function () {
  // DropCap.js
  if (window.Dropcap) {
    var dropcaps = document.querySelectorAll(".dropcap");
    if (dropcaps.length) {
      window.Dropcap.layout(dropcaps, 2);
    }
  }

  // Theme toggle
  var themeToggles = document.querySelectorAll(".theme-toggle");
  var mobileNavToggle = document.getElementById("mobile-nav-toggle");
  var topNav = document.querySelector(".top-nav");

  function applyTheme(theme) {
    var isDark = theme === "dark";
    document.documentElement.classList.toggle("theme-dark", isDark);

    var toggleLabel = isDark ? "Switch to light mode" : "Switch to dark mode";
    themeToggles.forEach(function (toggle) {
      toggle.setAttribute("aria-pressed", isDark ? "true" : "false");
      toggle.setAttribute("aria-label", toggleLabel);

      var toggleText = toggle.querySelector(".theme-toggle__text");
      var toggleIcon = toggle.querySelector(".theme-toggle__icon");

      if (toggleText) {
        toggleText.textContent = toggleLabel;
      }

      if (toggleIcon) {
        toggleIcon.classList.remove("ph-moon", "ph-sun");
        toggleIcon.classList.add(isDark ? "ph-sun" : "ph-moon");
      }
    });
  }

  var storedTheme = null;
  try {
    storedTheme = localStorage.getItem("theme");
  } catch (e) {
    storedTheme = null;
  }

  applyTheme(storedTheme === "dark" ? "dark" : "light");

  if (themeToggles.length) {
    themeToggles.forEach(function (toggle) {
      toggle.addEventListener("click", function () {
        var isDark = document.documentElement.classList.contains("theme-dark");
        var nextTheme = isDark ? "light" : "dark";
        applyTheme(nextTheme);

        try {
          localStorage.setItem("theme", nextTheme);
        } catch (e) {
          // no-op when storage is unavailable
        }
      });
    });
  }

  // Mobile nav toggle
  if (mobileNavToggle && topNav) {
    mobileNavToggle.addEventListener("click", function () {
      var isOpen = topNav.classList.toggle("is-open");
      mobileNavToggle.setAttribute("aria-expanded", isOpen ? "true" : "false");
      var icon = mobileNavToggle.querySelector("i");
      if (icon) {
        icon.classList.remove("ph-list", "ph-x");
        icon.classList.add(isOpen ? "ph-x" : "ph-list");
      }
    });
  }

  // Round reading time
  var times = document.querySelectorAll(".time");
  times.forEach(function (node) {
    var value = parseFloat(node.textContent);
    if (!isNaN(value)) {
      node.textContent = String(Math.round(value));
    }
  });
});
