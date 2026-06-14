document.addEventListener("DOMContentLoaded", function () {
  function initPageEntrance() {
    var root = document.documentElement;

    if (!root.classList.contains("page-entering")) {
      return;
    }

    window.requestAnimationFrame(function () {
      window.requestAnimationFrame(function () {
        document.documentElement.classList.add("page-ready");
      });
    });
  }

  // DropCap.js
  if (window.Dropcap) {
    var dropcaps = document.querySelectorAll(".dropcap");
    if (dropcaps.length) {
      window.Dropcap.layout(dropcaps, 2);
    }
  }

  // Theme toggle
  var mobileNavToggle = document.getElementById("mobile-nav-toggle");
  var topNav = document.querySelector(".top-nav");
  var header = document.querySelector(".header");

  function getThemeToggles() {
    return document.querySelectorAll(".theme-toggle");
  }

  var themeAudioContext = null;

  function getThemeAudioContext() {
    var AudioContextConstructor = window.AudioContext || window.webkitAudioContext;

    if (!AudioContextConstructor) {
      return null;
    }

    if (!themeAudioContext) {
      themeAudioContext = new AudioContextConstructor();
    }

    return themeAudioContext;
  }

  function playThemeToggleSound() {
    var context = getThemeAudioContext();

    if (!context) {
      return;
    }

    function play() {
      var now = context.currentTime;
      var oscillator = context.createOscillator();
      var gain = context.createGain();
      var noiseBuffer = context.createBuffer(1, Math.floor(context.sampleRate * 0.045), context.sampleRate);
      var noiseData = noiseBuffer.getChannelData(0);
      var noise = context.createBufferSource();
      var noiseGain = context.createGain();
      var filter = context.createBiquadFilter();

      for (var i = 0; i < noiseData.length; i += 1) {
        noiseData[i] = (Math.random() * 2 - 1) * (1 - i / noiseData.length);
      }

      oscillator.type = "sine";
      oscillator.frequency.setValueAtTime(520, now);
      oscillator.frequency.exponentialRampToValueAtTime(320, now + 0.07);

      gain.gain.setValueAtTime(0.0001, now);
      gain.gain.exponentialRampToValueAtTime(0.026, now + 0.008);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.075);

      filter.type = "bandpass";
      filter.frequency.setValueAtTime(1800, now);
      filter.Q.setValueAtTime(0.7, now);

      noise.buffer = noiseBuffer;
      noiseGain.gain.setValueAtTime(0.0001, now);
      noiseGain.gain.exponentialRampToValueAtTime(0.018, now + 0.006);
      noiseGain.gain.exponentialRampToValueAtTime(0.0001, now + 0.04);

      oscillator.connect(gain);
      gain.connect(context.destination);
      noise.connect(filter);
      filter.connect(noiseGain);
      noiseGain.connect(context.destination);
      oscillator.start(now);
      oscillator.stop(now + 0.08);
      noise.start(now);
      noise.stop(now + 0.045);
    }

    try {
      if (context.state === "suspended") {
        context.resume().then(play).catch(function () {});
      } else {
        play();
      }
    } catch (e) {
      // no-op when browser audio is unavailable
    }
  }

  function animateThemeToggleIcon(toggle) {
    toggle.classList.remove("is-icon-swapping");
    void toggle.offsetWidth;
    toggle.classList.add("is-icon-swapping");

    window.setTimeout(function () {
      toggle.classList.remove("is-icon-swapping");
    }, 460);
  }

  function applyTheme(theme, animateIcon) {
    var isDark = theme === "dark";
    document.documentElement.classList.toggle("theme-dark", isDark);

    var toggleLabel = isDark ? "Switch to light mode" : "Switch to dark mode";
    getThemeToggles().forEach(function (toggle) {
      toggle.setAttribute("aria-pressed", isDark ? "true" : "false");
      toggle.setAttribute("aria-label", toggleLabel);
      toggle.setAttribute("title", toggleLabel);

      var toggleIcon = toggle.querySelector(".theme-toggle__icon");
      var toggleText = toggle.querySelector(".theme-toggle__text");

      if (toggleIcon) {
        toggleIcon.classList.remove("ph-moon", "ph-sun");
        toggleIcon.classList.add(isDark ? "ph-moon" : "ph-sun");
      }

      if (toggleText) {
        toggleText.textContent = toggleLabel;
      }

      if (animateIcon && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
        animateThemeToggleIcon(toggle);
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

  document.addEventListener("click", function (event) {
    var toggle = event.target.closest(".theme-toggle");
    if (!toggle) {
      return;
    }

    var isDark = document.documentElement.classList.contains("theme-dark");
    var nextTheme = isDark ? "light" : "dark";
    applyTheme(nextTheme, true);
    playThemeToggleSound();

    try {
      localStorage.setItem("theme", nextTheme);
    } catch (e) {
      // no-op when storage is unavailable
    }
  });

  // Mobile nav toggle
  if (mobileNavToggle && topNav) {
    mobileNavToggle.addEventListener("click", function () {
      var isOpen = topNav.classList.toggle("is-open");
      if (header) {
        header.classList.toggle("menu-open", isOpen);
      }
      mobileNavToggle.setAttribute("aria-expanded", isOpen ? "true" : "false");
      var icon = mobileNavToggle.querySelector("i");
      if (icon) {
        icon.classList.remove("ph-list", "ph-x");
        icon.classList.add(isOpen ? "ph-x" : "ph-list");
      }
    });
  }

  // Prototype videos
  document.querySelectorAll(".prototype-list__thumbnail[data-video-id]").forEach(function (link) {
    link.addEventListener("click", function (event) {
      if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
        return;
      }

      var videoId = link.getAttribute("data-video-id");
      if (!videoId) {
        return;
      }

      event.preventDefault();

      var title = link.getAttribute("data-video-title") || "Prototype video";
      var embed = document.createElement("div");
      var iframe = document.createElement("iframe");

      embed.className = link.className + " is-playing";
      embed.setAttribute("aria-label", "Playing " + title);

      iframe.className = "prototype-list__embed";
      iframe.src = "https://www.youtube-nocookie.com/embed/" + encodeURIComponent(videoId) + "?autoplay=1&rel=0";
      iframe.title = title;
      iframe.setAttribute("allow", "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share");
      iframe.allowFullscreen = true;

      embed.appendChild(iframe);
      link.replaceWith(embed);
    });
  });

  // Case study section nav
  function initCaseStudySectionNav() {
    var shell = document.querySelector("[data-case-study-shell]");
    var content = document.querySelector("[data-case-study-content]");
    var nav = document.querySelector("[data-case-study-nav]");
    var list = document.querySelector("[data-case-study-nav-list]");
    var dot = document.querySelector(".case-study-section-nav__dot");

    if (!shell || !content || !nav || !list || !dot) {
      return;
    }

    function directChildren(element, tagName) {
      return Array.prototype.filter.call(element.children, function (child) {
        return child.tagName === tagName;
      });
    }

    function firstDirectHeading(section) {
      var headings = directChildren(section, "H3");
      return headings.length ? headings[0] : null;
    }

    function getNavHeadings() {
      var headings = [];
      var sections = directChildren(content, "SECTION");

      sections.forEach(function (section) {
        var heading = firstDirectHeading(section);
        if (heading) {
          headings.push(heading);
        }
      });

      if (!headings.length) {
        headings = directChildren(content, "H3");
      }

      return headings;
    }

    function slugify(text) {
      var slug = text.toLowerCase()
        .trim()
        .replace(/&/g, " and ")
        .replace(/[^a-z0-9\s-]/g, "")
        .replace(/\s+/g, "-")
        .replace(/-+/g, "-")
        .replace(/^-|-$/g, "");

      return slug || "section";
    }

    function ensureHeadingId(heading) {
      if (heading.id) {
        return heading.id;
      }

      var baseId = slugify(heading.textContent || "section");
      var id = baseId;
      var index = 2;

      while (document.getElementById(id)) {
        id = baseId + "-" + index;
        index += 1;
      }

      heading.id = id;
      return id;
    }

    var headings = getNavHeadings();

    if (headings.length < 2) {
      shell.classList.add("case-study-shell--nav-hidden");
      return;
    }

    var items = headings.map(function (heading, index) {
      var id = ensureHeadingId(heading);
      var item = document.createElement("li");
      var link = document.createElement("a");

      item.className = "case-study-section-nav__item";
      item.style.setProperty("--case-study-nav-index", index);

      link.className = "case-study-section-nav__link";
      link.href = "#" + id;
      link.textContent = heading.textContent.trim().replace(/\s+/g, " ");
      link.setAttribute("data-case-study-nav-link", id);

      item.appendChild(link);
      list.appendChild(item);

      return {
        id: id,
        heading: heading,
        item: item,
        link: link
      };
    });

    function updateDotPosition(activeItem) {
      if (!activeItem) {
        return;
      }

      nav.style.setProperty("--case-study-dot-y", activeItem.offsetTop + "px");
    }

    function setActive(id) {
      var activeItem = null;

      items.forEach(function (item) {
        var isActive = item.id === id;
        item.link.classList.toggle("is-active", isActive);
        item.item.classList.toggle("is-active", isActive);

        if (isActive) {
          item.link.setAttribute("aria-current", "true");
          activeItem = item.item;
        } else {
          item.link.removeAttribute("aria-current");
        }
      });

      if (activeItem) {
        nav.classList.add("has-active");
        updateDotPosition(activeItem);
      }
    }

    function updateActiveFromViewport() {
      var triggerY = window.innerHeight * 0.35;
      var active = items[0];

      items.forEach(function (item) {
        var rect = item.heading.getBoundingClientRect();
        if (rect.top <= triggerY) {
          active = item;
        }
      });

      setActive(active.id);
    }

    var updateQueued = false;
    function queueActiveUpdate() {
      if (updateQueued) {
        return;
      }

      updateQueued = true;
      window.requestAnimationFrame(function () {
        updateQueued = false;
        updateActiveFromViewport();
      });
    }

    items.forEach(function (item) {
      item.link.addEventListener("click", function () {
        setActive(item.id);
      });
    });

    if ("IntersectionObserver" in window) {
      var observer = new IntersectionObserver(queueActiveUpdate, {
        rootMargin: "-20% 0px -65% 0px",
        threshold: [0, 1]
      });

      items.forEach(function (item) {
        observer.observe(item.heading);
      });
    }

    window.addEventListener("scroll", queueActiveUpdate, { passive: true });
    window.addEventListener("resize", queueActiveUpdate);

    setActive(items[0].id);
  }

  initCaseStudySectionNav();
  initPageEntrance();

  // Round reading time
  var times = document.querySelectorAll(".time");
  times.forEach(function (node) {
    var value = parseFloat(node.textContent);
    if (!isNaN(value)) {
      node.textContent = String(Math.round(value));
    }
  });
});
