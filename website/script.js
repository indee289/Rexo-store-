/**
 * Rexo Agency — Website JavaScript
 * Pure vanilla JS, no dependencies.
 *
 * Features:
 *  1. Sticky nav — background blur on scroll
 *  2. Mobile hamburger menu — open/close with animation
 *  3. Smooth scroll — close mobile menu on link click
 *  4. Contact form — client-side validation + success state
 */

'use strict';

/* ── Utilities ─────────────────────────────────────────────────── */
const $ = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => [...ctx.querySelectorAll(sel)];

/* ═══════════════════════════════════════════════════════════════
   1. STICKY NAV — add .scrolled class after 10px scroll
════════════════════════════════════════════════════════════════ */
(function initNav() {
  const nav = $('#nav');
  if (!nav) return;

  let ticking = false;

  function onScroll() {
    if (!ticking) {
      requestAnimationFrame(() => {
        if (window.scrollY > 10) {
          nav.classList.add('scrolled');
        } else {
          nav.classList.remove('scrolled');
        }
        ticking = false;
      });
      ticking = true;
    }
  }

  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll(); // Run once on load
})();


/* ═══════════════════════════════════════════════════════════════
   2. MOBILE HAMBURGER MENU
════════════════════════════════════════════════════════════════ */
(function initMobileMenu() {
  const hamburger  = $('#hamburger');
  const mobileMenu = $('#mobileMenu');
  const menuClose  = $('#menuClose');
  const menuLinks  = $$('.mobile-menu__link');
  const menuCta    = $('.mobile-menu__cta');

  if (!hamburger || !mobileMenu) return;

  function openMenu() {
    mobileMenu.classList.add('open');
    document.body.style.overflow = 'hidden';
    hamburger.setAttribute('aria-expanded', 'true');

    // Animate hamburger → X
    const spans = $$('span', hamburger);
    if (spans[0]) spans[0].style.transform = 'translateY(7px) rotate(45deg)';
    if (spans[1]) spans[1].style.opacity = '0';
    if (spans[2]) spans[2].style.transform = 'translateY(-7px) rotate(-45deg)';
  }

  function closeMenu() {
    mobileMenu.classList.remove('open');
    document.body.style.overflow = '';
    hamburger.setAttribute('aria-expanded', 'false');

    // Animate back to hamburger
    const spans = $$('span', hamburger);
    if (spans[0]) spans[0].style.transform = '';
    if (spans[1]) spans[1].style.opacity = '';
    if (spans[2]) spans[2].style.transform = '';
  }

  hamburger.addEventListener('click', openMenu);
  menuClose.addEventListener('click', closeMenu);

  // Close on any mobile menu link tap
  [...menuLinks, menuCta].forEach(el => {
    if (el) el.addEventListener('click', closeMenu);
  });

  // Close on Escape key
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && mobileMenu.classList.contains('open')) {
      closeMenu();
    }
  });

  // Close when clicking outside the menu content (on the overlay background)
  mobileMenu.addEventListener('click', e => {
    if (e.target === mobileMenu) closeMenu();
  });
})();


/* ═══════════════════════════════════════════════════════════════
   3. SMOOTH SCROLL — close mobile menu and scroll to section
      (CSS scroll-behavior handles the actual smooth scroll,
       this just closes the menu on nav link clicks)
════════════════════════════════════════════════════════════════ */
(function initSmoothScroll() {
  $$('a[href^="#"]').forEach(link => {
    link.addEventListener('click', e => {
      const target = $(link.getAttribute('href'));
      if (!target) return;
      // Scroll is handled by CSS scroll-behavior: smooth on html
      // We just let the native behavior run
    });
  });
})();


/* ═══════════════════════════════════════════════════════════════
   4. CONTACT FORM — validation + success state
════════════════════════════════════════════════════════════════ */
(function initContactForm() {
  const form       = $('#contactForm');
  const submitBtn  = $('#submitBtn');
  const successDiv = $('#formSuccess');

  if (!form) return;

  /* ── Field validation helpers ── */
  function isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
  }

  function showError(input, message) {
    clearError(input);
    input.style.borderColor = '#c0392b';
    const errEl = document.createElement('span');
    errEl.className = 'form-field-error';
    errEl.style.cssText = 'font-size:12px;color:#e74c3c;margin-top:4px;display:block;';
    errEl.textContent = message;
    input.parentElement.appendChild(errEl);
  }

  function clearError(input) {
    input.style.borderColor = '';
    const existing = input.parentElement.querySelector('.form-field-error');
    if (existing) existing.remove();
  }

  function clearAllErrors() {
    $$('.form-field-error', form).forEach(el => el.remove());
    $$('.form-input', form).forEach(inp => inp.style.borderColor = '');
  }

  /* ── Validate all fields ── */
  function validateForm() {
    let valid = true;
    clearAllErrors();

    const name    = $('#name', form);
    const company = $('#company', form);
    const email   = $('#email', form);
    const service = $('#service', form);

    if (!name.value.trim()) {
      showError(name, 'Please enter your name.');
      valid = false;
    }

    if (!company.value.trim()) {
      showError(company, 'Please enter your company or brand name.');
      valid = false;
    }

    if (!email.value.trim()) {
      showError(email, 'Please enter your email address.');
      valid = false;
    } else if (!isValidEmail(email.value)) {
      showError(email, 'Please enter a valid email address.');
      valid = false;
    }

    if (!service.value) {
      showError(service, 'Please select a service.');
      valid = false;
    }

    return valid;
  }

  /* ── Clear errors on input ── */
  $$('.form-input', form).forEach(input => {
    input.addEventListener('input', () => clearError(input));
    input.addEventListener('change', () => clearError(input));
  });

  /* ── Submit handler ── */
  form.addEventListener('submit', function handleSubmit(e) {
    e.preventDefault();

    if (!validateForm()) return;

    // Disable button and show loading state
    submitBtn.disabled = true;
    submitBtn.textContent = 'Sending…';
    submitBtn.style.opacity = '0.75';

    // Simulate async submission (replace with fetch() for real backend)
    setTimeout(() => {
      // Hide the form fields and submit button
      $$('.form-group', form).forEach(el => el.style.display = 'none');
      $('.contact-form__row', form).style.display = 'none';
      submitBtn.style.display = 'none';

      // Show success state
      successDiv.style.display = 'block';
      successDiv.setAttribute('aria-live', 'polite');

      // Optional: scroll success into view
      successDiv.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }, 1200);
  });
})();


/* ═══════════════════════════════════════════════════════════════
   5. SCROLL ANIMATIONS — subtle entrance for cards
      Uses IntersectionObserver for performance
════════════════════════════════════════════════════════════════ */
(function initScrollAnimations() {
  if (!('IntersectionObserver' in window)) return;

  const style = document.createElement('style');
  style.textContent = `
    .fade-in-up {
      opacity: 0;
      transform: translateY(20px);
      transition: opacity 0.45s ease, transform 0.45s ease;
    }
    .fade-in-up.visible {
      opacity: 1;
      transform: translateY(0);
    }
  `;
  document.head.appendChild(style);

  const targets = [
    ...$$('.service-card'),
    ...$$('.campster__feature'),
    ...$$('.how__step'),
    ...$$('.testimonial-card'),
    ...$$('.market-card'),
  ];

  targets.forEach((el, i) => {
    el.classList.add('fade-in-up');
    el.style.transitionDelay = `${(i % 4) * 0.06}s`;
  });

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });

  targets.forEach(el => observer.observe(el));
})();


/* ═══════════════════════════════════════════════════════════════
   6. ACTIVE NAV LINK — highlight current section in nav
════════════════════════════════════════════════════════════════ */
(function initActiveNavLink() {
  const navLinks = $$('.nav__link');
  const sections = navLinks
    .map(link => $(link.getAttribute('href')))
    .filter(Boolean);

  if (!sections.length) return;

  const NAV_HEIGHT = 80;

  function setActiveLink() {
    const scrollY = window.scrollY + NAV_HEIGHT + 40;

    let currentSection = sections[0];
    sections.forEach(section => {
      if (section.offsetTop <= scrollY) {
        currentSection = section;
      }
    });

    navLinks.forEach(link => {
      const href = link.getAttribute('href').slice(1);
      if (currentSection && currentSection.id === href) {
        link.style.color = '#e74c3c';
      } else {
        link.style.color = '';
      }
    });
  }

  let ticking = false;
  window.addEventListener('scroll', () => {
    if (!ticking) {
      requestAnimationFrame(() => {
        setActiveLink();
        ticking = false;
      });
      ticking = true;
    }
  }, { passive: true });

  setActiveLink();
})();
