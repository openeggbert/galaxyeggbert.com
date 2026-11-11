/* Galaxy Eggbert website: small, dependency-free enhancements. */
(function () {
  "use strict";
  document.documentElement.classList.add("js");
  // "?static" turns off the scroll effects and lazy loading (full-page screenshots, print).
  var staticPage = /[?&]static\b/.test(location.search);

  var $ = function (sel, root) { return (root || document).querySelector(sel); };
  var $$ = function (sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); };

  /* ---------- mobile navigation ---------- */
  var toggle = $(".nav-toggle");
  var nav = $("#site-nav");
  if (toggle && nav) {
    var setOpen = function (open) {
      nav.classList.toggle("open", open);
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    };
    toggle.addEventListener("click", function () { setOpen(!nav.classList.contains("open")); });
    $$("a", nav).forEach(function (a) { a.addEventListener("click", function () { setOpen(false); }); });
    document.addEventListener("keydown", function (e) { if (e.key === "Escape") setOpen(false); });
  }

  /* ---------- highlight the section in view ---------- */
  var navLinks = $$('.site-nav a[href^="#"]');
  if ("IntersectionObserver" in window && navLinks.length) {
    var byId = {};
    navLinks.forEach(function (a) { byId[a.getAttribute("href").slice(1)] = a; });
    var spy = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        var link = byId[entry.target.id];
        if (!link) return;
        if (entry.isIntersecting) {
          navLinks.forEach(function (l) { l.removeAttribute("aria-current"); });
          link.setAttribute("aria-current", "true");
        }
      });
    }, { rootMargin: "-45% 0px -50% 0px" });
    Object.keys(byId).forEach(function (id) { var s = document.getElementById(id); if (s) spy.observe(s); });
  }

  /* ---------- gallery (rendered from gallery-data.js) ---------- */
  var gallery = $("#gallery");
  var shots = window.GALAXY_GALLERY || [];
  if (gallery && shots.length) {
    var frag = document.createDocumentFragment();
    shots.forEach(function (s, i) {
      var a = document.createElement("a");
      a.href = "assets/shots/" + s.file;
      a.setAttribute("data-lightbox", "gallery");
      a.setAttribute("data-caption", s.caption);
      if (s.wide) a.className = "wide";
      var img = document.createElement("img");
      img.src = "assets/shots/thumb/" + s.file;
      img.alt = s.caption;
      img.width = 800; img.height = 480;
      img.loading = (i < 3 || staticPage) ? "eager" : "lazy";
      img.decoding = "async";
      a.appendChild(img);
      frag.appendChild(a);
    });
    gallery.appendChild(frag);
  }

  /* ---------- lightbox ---------- */
  var lb = $("#lightbox");
  if (lb && typeof lb.showModal === "function") {
    var lbImg = $("#lightbox-img"), lbCap = $("#lightbox-cap"), lbCount = $("#lightbox-count");
    var group = [], index = 0, lastFocus = null;

    var show = function (i) {
      index = (i + group.length) % group.length;
      var a = group[index];
      lbImg.src = a.getAttribute("href");
      lbImg.alt = a.getAttribute("data-caption") || "";
      lbCap.textContent = a.getAttribute("data-caption") || "";
      lbCount.textContent = group.length > 1 ? (index + 1) + " / " + group.length : "";
      // warm the cache for the neighbours
      [index + 1, index - 1].forEach(function (n) {
        var b = group[(n + group.length) % group.length];
        if (b) { var pre = new Image(); pre.src = b.getAttribute("href"); }
      });
    };

    document.addEventListener("click", function (e) {
      var a = e.target.closest && e.target.closest("a[data-lightbox]");
      if (!a || e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return;
      e.preventDefault();
      var name = a.getAttribute("data-lightbox");
      group = $$('a[data-lightbox="' + name + '"]');
      lastFocus = a;
      show(group.indexOf(a));
      lb.showModal();
    });

    lb.addEventListener("click", function (e) {
      var act = e.target.closest("[data-lb]");
      if (act) {
        var what = act.getAttribute("data-lb");
        if (what === "close") lb.close();
        else show(index + (what === "next" ? 1 : -1));
        return;
      }
      if (e.target === lb || e.target.tagName === "FIGURE") lb.close();
    });
    lb.addEventListener("keydown", function (e) {
      if (e.key === "ArrowRight") { e.preventDefault(); show(index + 1); }
      else if (e.key === "ArrowLeft") { e.preventDefault(); show(index - 1); }
    });
    lb.addEventListener("close", function () {
      lbImg.src = "data:,";
      if (lastFocus) lastFocus.focus({ preventScroll: true });
    });

    // swipe on touch screens
    var x0 = null;
    lb.addEventListener("touchstart", function (e) { x0 = e.touches[0].clientX; }, { passive: true });
    lb.addEventListener("touchend", function (e) {
      if (x0 === null) return;
      var dx = e.changedTouches[0].clientX - x0;
      if (Math.abs(dx) > 50) show(index + (dx < 0 ? 1 : -1));
      x0 = null;
    });
  }

  if (staticPage) $$('img[loading="lazy"]').forEach(function (img) { img.loading = "eager"; });

  /* ---------- links to a <details> open it ---------- */
  var openTarget = function () {
    var id = location.hash.slice(1);
    var el = id && document.getElementById(id);
    if (el && el.tagName === "DETAILS") el.open = true;
  };
  window.addEventListener("hashchange", openTarget);
  openTarget();

  /* ---------- before / after compare ---------- */
  $$("[data-compare]").forEach(function (box) {
    var range = $(".compare-range", box);
    if (!range) return;
    var set = function () { box.style.setProperty("--pos", range.value + "%"); };
    range.addEventListener("input", set);
    set();
  });

  /* ---------- tabs (WAI-ARIA pattern) ---------- */
  $$("[data-tabs]").forEach(function (wrap) {
    var tabs = $$('[role="tab"]', wrap);
    var select = function (tab, focus) {
      tabs.forEach(function (t) {
        var on = t === tab;
        t.setAttribute("aria-selected", on ? "true" : "false");
        t.tabIndex = on ? 0 : -1;
        var panel = document.getElementById(t.getAttribute("aria-controls"));
        if (panel) panel.hidden = !on;
      });
      if (focus) tab.focus();
    };
    tabs.forEach(function (t, i) {
      t.addEventListener("click", function () { select(t, false); });
      t.addEventListener("keydown", function (e) {
        var n = null;
        if (e.key === "ArrowRight") n = tabs[(i + 1) % tabs.length];
        else if (e.key === "ArrowLeft") n = tabs[(i - 1 + tabs.length) % tabs.length];
        else if (e.key === "Home") n = tabs[0];
        else if (e.key === "End") n = tabs[tabs.length - 1];
        if (n) { e.preventDefault(); select(n, true); }
      });
    });
    // touch devices see the touch controls first
    if (window.matchMedia && window.matchMedia("(pointer: coarse)").matches) {
      var touch = $("#tab-touch", wrap);
      if (touch) select(touch, false);
    }
  });

  /* ---------- point out the visitor's platform in Downloads ---------- */
  (function () {
    var ua = navigator.userAgent || "";
    var plat = (navigator.userAgentData && navigator.userAgentData.platform) || navigator.platform || "";
    var key = null;
    if (/android/i.test(ua)) key = "android";
    else if (/iphone|ipad|ipod/i.test(ua) || (/mac/i.test(plat) && navigator.maxTouchPoints > 1)) key = "ios";
    else if (/win/i.test(plat) || /windows/i.test(ua)) key = "windows";
    else if (/mac/i.test(plat)) key = "macos";
    else if (/linux|x11/i.test(plat + ua)) key = "linux";
    if (!key) return;
    var card = $('.dl[data-platform="' + key + '"]');
    if (card) card.classList.add("is-you");
  })();

  /* ---------- gentle reveal on scroll ---------- */
  if (!staticPage && "IntersectionObserver" in window && !(window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches)) {
    var targets = $$(".pillar, .feature, .fx, .mini, .world, .bonus, .dl, .tech, .road-col, .link-card, .stats li, .timeline li");
    targets.forEach(function (el) { el.classList.add("reveal"); });
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) { entry.target.classList.add("is-visible"); io.unobserve(entry.target); }
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
    targets.forEach(function (el) { io.observe(el); });
  }
})();
