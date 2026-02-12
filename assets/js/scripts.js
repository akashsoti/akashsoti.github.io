// A $( document ).ready() block.
$( document ).ready(function() {

	// DropCap.js
	var dropcaps = document.querySelectorAll(".dropcap");
	window.Dropcap.layout(dropcaps, 2);

	// Legacy responsive-nav initialization intentionally removed.
	// Navigation now uses a static shadcn-style layout in the header include.

	// Theme toggle
	var $themeToggle = $("#theme-toggle");
	var $themeToggleText = $themeToggle.find(".theme-toggle__text");
	var $themeToggleIcon = $themeToggle.find(".theme-toggle__icon");

	function applyTheme(theme) {
		var isDark = theme === "dark";
		document.documentElement.classList.toggle("theme-dark", isDark);

		if ($themeToggle.length) {
			var toggleLabel = isDark ? "Switch to light mode" : "Switch to dark mode";
			$themeToggle.attr("aria-pressed", isDark ? "true" : "false");
			$themeToggle.attr("aria-label", toggleLabel);
			if ($themeToggleText.length) {
				$themeToggleText.text(toggleLabel);
			}
			$themeToggleIcon.removeClass("ph-moon ph-sun").addClass(isDark ? "ph-sun" : "ph-moon");
		}
	}

	var storedTheme = null;
	try {
		storedTheme = localStorage.getItem("theme");
	} catch (e) {}
	applyTheme(storedTheme === "dark" ? "dark" : "light");

	$themeToggle.on("click", function () {
		var isDark = document.documentElement.classList.contains("theme-dark");
		var nextTheme = isDark ? "light" : "dark";
		applyTheme(nextTheme);
		try {
			localStorage.setItem("theme", nextTheme);
		} catch (e) {}
	});

	// Round Reading Time
    $(".time").text(function (index, value) {
      return Math.round(parseFloat(value));
    });

});
