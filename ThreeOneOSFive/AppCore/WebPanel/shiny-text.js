function parseConfig(el, overrides = {}) {
  return {
    color: overrides.color ?? el.dataset.shinyColor ?? '#b5b5b5',
    shineColor: overrides.shineColor ?? el.dataset.shinyShineColor ?? '#ffffff',
    speed: overrides.speed ?? parseFloat(el.dataset.shinySpeed || '2'),
    delay: overrides.delay ?? parseFloat(el.dataset.shinyDelay || '0'),
    spread: overrides.spread ?? parseFloat(el.dataset.shinySpread || '120'),
    direction: overrides.direction ?? el.dataset.shinyDirection ?? 'left',
    yoyo: overrides.yoyo ?? el.dataset.shinyYoyo === 'true',
    pauseOnHover: overrides.pauseOnHover ?? el.dataset.shinyPauseOnHover === 'true',
    disabled: overrides.disabled ?? el.dataset.shinyDisabled === 'true',
  };
}

export function createShinyText(element, overrides = {}) {
  if (!element) return null;

  const config = parseConfig(element, overrides);
  const reduceMotion =
    typeof window !== 'undefined' &&
    window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  element.classList.add('shiny-text');
  element.style.display = 'inline-block';

  if (reduceMotion || config.disabled) {
    element.style.background = 'none';
    element.style.webkitTextFillColor = '';
    element.style.color = config.color;
    return {
      pause() {},
      resume() {},
      setDisabled() {},
      destroy() {},
    };
  }

  element.style.backgroundSize = '200% auto';
  element.style.webkitBackgroundClip = 'text';
  element.style.backgroundClip = 'text';
  element.style.webkitTextFillColor = 'transparent';
  element.style.color = 'transparent';

  const applyGradient = () => {
    element.style.backgroundImage =
      'linear-gradient(' +
      config.spread +
      'deg, ' +
      config.color +
      ' 0%, ' +
      config.color +
      ' 35%, ' +
      config.shineColor +
      ' 50%, ' +
      config.color +
      ' 65%, ' +
      config.color +
      ' 100%)';
  };

  applyGradient();

  let elapsed = 0;
  let lastTime = null;
  let directionMul = config.direction === 'left' ? 1 : -1;
  let isPaused = false;
  let isDisabled = false;
  let rafId = 0;
  let destroyed = false;

  const animDuration = config.speed * 1000;
  const delayDuration = config.delay * 1000;

  const setProgress = (progress) => {
    element.style.backgroundPosition = 150 - progress * 2 + '% center';
  };

  const tick = (time) => {
    if (destroyed) return;
    rafId = requestAnimationFrame(tick);

    if (isDisabled || isPaused) {
      lastTime = null;
      return;
    }

    if (lastTime === null) {
      lastTime = time;
      return;
    }

    const delta = time - lastTime;
    lastTime = time;
    elapsed += delta;

    let progress = 0;

    if (config.yoyo) {
      const cycleDuration = animDuration + delayDuration;
      const fullCycle = cycleDuration * 2;
      const cycleTime = elapsed % fullCycle;

      if (cycleTime < animDuration) {
        progress = (cycleTime / animDuration) * 100;
      } else if (cycleTime < cycleDuration) {
        progress = 100;
      } else if (cycleTime < cycleDuration + animDuration) {
        const reverseTime = cycleTime - cycleDuration;
        progress = 100 - (reverseTime / animDuration) * 100;
      } else {
        progress = 0;
      }

      progress = directionMul === 1 ? progress : 100 - progress;
    } else {
      const cycleDuration = animDuration + delayDuration;
      const cycleTime = elapsed % cycleDuration;

      if (cycleTime < animDuration) {
        progress = (cycleTime / animDuration) * 100;
      } else {
        progress = 100;
      }

      progress = directionMul === 1 ? progress : 100 - progress;
    }

    setProgress(progress);
  };

  const onEnter = () => {
    if (config.pauseOnHover) isPaused = true;
  };
  const onLeave = () => {
    if (config.pauseOnHover) isPaused = false;
  };

  if (config.pauseOnHover) {
    element.addEventListener('mouseenter', onEnter);
    element.addEventListener('mouseleave', onLeave);
  }

  setProgress(0);
  rafId = requestAnimationFrame(tick);

  return {
    pause() {
      isPaused = true;
    },
    resume() {
      isPaused = false;
      lastTime = null;
    },
    setDisabled(value) {
      isDisabled = !!value;
      if (isDisabled) {
        element.style.background = 'none';
        element.style.webkitTextFillColor = '';
        element.style.color = config.color;
      } else {
        applyGradient();
        element.style.webkitTextFillColor = 'transparent';
        element.style.color = 'transparent';
        lastTime = null;
      }
    },
    destroy() {
      destroyed = true;
      cancelAnimationFrame(rafId);
      if (config.pauseOnHover) {
        element.removeEventListener('mouseenter', onEnter);
        element.removeEventListener('mouseleave', onLeave);
      }
    },
  };
}

export function initShinyTexts(selector = '[data-shiny-text]') {
  const instances = new Map();
  document.querySelectorAll(selector).forEach((el) => {
    instances.set(el, createShinyText(el));
  });
  return instances;
}
