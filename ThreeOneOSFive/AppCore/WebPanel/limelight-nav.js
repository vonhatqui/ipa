export function initLimelightNav(root, options = {}) {
  if (!root) return null;

  var inner = root.querySelector('.dock-inner') || root;
  var limelight = root.querySelector('.dock-limelight');
  var bar = limelight && limelight.querySelector('.dock-limelight-bar');
  var itemSelector = options.itemSelector || '[data-tab]';
  var items = Array.prototype.slice.call(root.querySelectorAll(itemSelector));
  var isReady = false;
  var animating = false;
  var resizeTimer = 0;
  var animLockTimer = 0;
  var activeAnim = null;
  var reduceMotion =
    typeof window !== 'undefined' &&
    window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  // Keep dock limelight sliding even in native/fast UI (only respect reduced-motion).
  var DURATION = reduceMotion ? 0 : 420;
  var EASING = 'cubic-bezier(0.22, 1, 0.36, 1)';

  if (!limelight || !bar || !items.length) return null;

  function getActiveIndex() {
    for (var i = 0; i < items.length; i++) {
      if (items[i].classList.contains('is-on')) return i;
    }
    return 0;
  }

  function readTranslateX(el) {
    if (typeof DOMMatrix !== 'undefined') {
      var computed = window.getComputedStyle(el).transform;
      if (computed && computed !== 'none') {
        return new DOMMatrix(computed).m41;
      }
    }
    var inline = el.style.transform || '';
    var match = inline.match(/translate3d\(\s*([-\d.]+)px/i);
    if (match) return parseFloat(match[1]);
    return 0;
  }

  function setTranslateX(left) {
    limelight.style.transform = 'translate3d(' + left + 'px, 0, 0)';
  }

  function cancelAnim() {
    var committed = readTranslateX(limelight);
    if (activeAnim) {
      activeAnim.cancel();
      activeAnim = null;
    }
    limelight.getAnimations().forEach(function (anim) {
      anim.cancel();
    });
    setTranslateX(committed);
    animating = false;
  }

  function animateTo(left, instant) {
    if (instant || !isReady || reduceMotion) {
      cancelAnim();
      animating = false;
      setTranslateX(left);
      return;
    }

    var from = readTranslateX(limelight);
    if (Math.abs(from - left) < 0.5) return;

    cancelAnim();
    animating = true;
    clearTimeout(animLockTimer);

    activeAnim = limelight.animate(
      [
        { transform: 'translate3d(' + from + 'px, 0, 0)' },
        { transform: 'translate3d(' + left + 'px, 0, 0)' },
      ],
      {
        duration: DURATION,
        easing: EASING,
        fill: 'forwards',
      }
    );

    activeAnim.onfinish = function () {
      setTranslateX(left);
      activeAnim = null;
      animating = false;
    };

    activeAnim.oncancel = function () {
      activeAnim = null;
      animating = false;
    };

    animLockTimer = setTimeout(function () {
      animating = false;
    }, DURATION + 40);
  }

  function positionLimelight(index, instant) {
    var item = items[index];
    if (!item) return;

    var innerRect = inner.getBoundingClientRect();
    var itemRect = item.getBoundingClientRect();
    var barWidth = bar.offsetWidth || 44;
    var left = itemRect.left - innerRect.left + itemRect.width / 2 - barWidth / 2;

    if (instant) {
      animateTo(left, true);
    } else {
      requestAnimationFrame(function () {
        requestAnimationFrame(function () {
          animateTo(left, false);
        });
      });
    }
  }

  function updateFromDom(instant) {
    positionLimelight(getActiveIndex(), instant);
  }

  function setActiveIndex(index) {
    if (index < 0 || index >= items.length) return;
    for (var i = 0; i < items.length; i++) {
      items[i].classList.toggle('is-on', i === index);
    }
    positionLimelight(index, !!reduceMotion);
  }

  var onResize = function () {
    if (animating) return;
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function () {
      if (!animating) updateFromDom(true);
    }, 32);
  };

  if (typeof ResizeObserver !== 'undefined') {
    var ro = new ResizeObserver(onResize);
    ro.observe(inner);
    ro.observe(root);
    root._limelightRo = ro;
  } else {
    window.addEventListener('resize', onResize);
    root._limelightResize = onResize;
  }

  requestAnimationFrame(function () {
    requestAnimationFrame(function () {
      updateFromDom(true);
      isReady = true;
      limelight.classList.add('is-ready');
    });
  });

  return {
    update: function (instant) {
      updateFromDom(!!instant);
    },
    setActiveIndex: setActiveIndex,
    destroy: function () {
      cancelAnim();
      clearTimeout(resizeTimer);
      clearTimeout(animLockTimer);
      if (root._limelightRo) {
        root._limelightRo.disconnect();
        root._limelightRo = null;
      }
      if (root._limelightResize) {
        window.removeEventListener('resize', root._limelightResize);
        root._limelightResize = null;
      }
    },
  };
}
