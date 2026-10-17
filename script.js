/**
 * Rexo Agency — Website JavaScript
 * Pure vanilla JS, no dependencies.
 *
 *  1. Sticky nav — background blur on scroll
 *  2. Mobile hamburger menu — open/close with animation
 *  3. Contact form — client-side validation + success state
 *  4. Scroll entrance animations
 *  5. Active nav link highlight
 */
'use strict';

const $  = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => [...ctx.querySelectorAll(sel)];

/* ── 1. STICKY NAV ─────────────────────────────────────────────── */
(function initNav() {
  const nav = $('#nav');
  if (!nav) return;
  let ticking = false;
  function onScroll() {
    if (!ticking) {
      requestAnimationFrame(() => {
        nav.classList.toggle('scrolled', window.scrollY > 10);
        ticking = false;
      });
      ticking = true;
    }
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
})();

/* ── 2. MOBILE HAMBURGER MENU ──────────────────────────────────── */
(function initMobileMenu() {
  const hamburger  = $('#hamburger');
  const mobileMenu = $('#mobileMenu');
  const menuClose  = $('#menuClose');
  if (!hamburger || !mobileMenu) return;

  const menuLinks = $$('.mobile-menu-link', mobileMenu);

  function openMenu() {
    mobileMenu.classList.add('open');
    document.body.style.overflow = 'hidden';
    hamburger.setAttribute('aria-expanded', 'true');
    const s = $$('span', hamburger);
    if (s[0]) s[0].style.transform = 'translateY(7px) rotate(45deg)';
    if (s[1]) s[1].style.opacity = '0';
    if (s[2]) s[2].style.transform = 'translateY(-7px) rotate(-45deg)';
  }
  function closeMenu() {
    mobileMenu.classList.remove('open');
    document.body.style.overflow = '';
    hamburger.setAttribute('aria-expanded', 'false');
    const s = $$('span', hamburger);
    if (s[0]) s[0].style.transform = '';
    if (s[1]) s[1].style.opacity = '';
    if (s[2]) s[2].style.transform = '';
  }

  hamburger.addEventListener('click', openMenu);
  if (menuClose) menuClose.addEventListener('click', closeMenu);
  menuLinks.forEach(el => el.addEventListener('click', closeMenu));
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && mobileMenu.classList.contains('open')) closeMenu();
  });
  mobileMenu.addEventListener('click', e => {
    if (e.target === mobileMenu) closeMenu();
  });
})();

/* ── 3. CONTACT FORM — validation + success ────────────────────── */
(function initContactForm() {
  const form       = $('#contactForm');
  const submitBtn  = $('#submitBtn');
  const successDiv = $('#formSuccess');
  if (!form) return;

  const isValidEmail = (e) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e.trim());

  function showError(input, msg) {
    clearError(input);
    input.style.borderColor = '#ED4956';
    const el = document.createElement('span');
    el.className = 'form-field-error';
    el.style.cssText = 'font-size:12px;color:#ED4956;margin-top:4px;display:block;';
    el.textContent = msg;
    input.parentElement.appendChild(el);
  }
  function clearError(input) {
    input.style.borderColor = '';
    const e = input.parentElement.querySelector('.form-field-error');
    if (e) e.remove();
  }
  function clearAll() {
    $$('.form-field-error', form).forEach(e => e.remove());
    $$('.form-input', form).forEach(i => i.style.borderColor = '');
  }

  function validate() {
    let ok = true;
    clearAll();
    const name = $('#name', form), company = $('#company', form),
          email = $('#email', form), service = $('#service', form);
    if (!name.value.trim())    { showError(name, 'Please enter your name.'); ok = false; }
    if (!company.value.trim()) { showError(company, 'Please enter your company or brand name.'); ok = false; }
    if (!email.value.trim())        { showError(email, 'Please enter your email.'); ok = false; }
    else if (!isValidEmail(email.value)) { showError(email, 'Please enter a valid email address.'); ok = false; }
    if (!service.value)        { showError(service, 'Please select a service.'); ok = false; }
    return ok;
  }

  $$('.form-input', form).forEach(input => {
    input.addEventListener('input',  () => clearError(input));
    input.addEventListener('change', () => clearError(input));
  });

  form.addEventListener('submit', e => {
    e.preventDefault();
    if (!validate()) return;
    submitBtn.disabled = true;
    submitBtn.textContent = 'Sending…';
    submitBtn.style.opacity = '0.75';
    setTimeout(() => {
      $$('.form-group', form).forEach(el => el.style.display = 'none');
      const row = $('.form-row', form);
      if (row) row.style.display = 'none';
      submitBtn.style.display = 'none';
      successDiv.style.display = 'block';
      successDiv.setAttribute('aria-live', 'polite');
      successDiv.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }, 1200);
  });
})();

/* ── 4. SCROLL ENTRANCE ANIMATIONS ─────────────────────────────── */
(function initScrollAnimations() {
  if (!('IntersectionObserver' in window)) return;
  const style = document.createElement('style');
  style.textContent =
    '.fade-in-up{opacity:0;transform:translateY(18px);transition:opacity .45s ease,transform .45s ease;}' +
    '.fade-in-up.visible{opacity:1;transform:translateY(0);}';
  document.head.appendChild(style);

  const targets = [
    ...$$('.svc-card'),
    ...$$('.cf-item'),
    ...$$('.how-step'),
    ...$$('.testi-card'),
    ...$$('.market-card'),
  ];
  targets.forEach((el, i) => {
    el.classList.add('fade-in-up');
    el.style.transitionDelay = `${(i % 4) * 0.06}s`;
  });

  const obs = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        obs.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });
  targets.forEach(el => obs.observe(el));
})();

/* ── 5. ACTIVE NAV LINK HIGHLIGHT ──────────────────────────────── */
(function initActiveNavLink() {
  const navLinks = $$('.nav-link');
  const sections = navLinks
    .map(link => { const h = link.getAttribute('href'); return h && h.startsWith('#') ? $(h) : null; })
    .filter(Boolean);
  if (!sections.length) return;

  const NAV_H = 80;
  function setActive() {
    const y = window.scrollY + NAV_H + 40;
    let current = sections[0];
    sections.forEach(s => { if (s.offsetTop <= y) current = s; });
    navLinks.forEach(link => {
      const href = link.getAttribute('href').slice(1);
      link.style.color = (current && current.id === href) ? '#0095F6' : '';
    });
  }
  let ticking = false;
  window.addEventListener('scroll', () => {
    if (!ticking) {
      requestAnimationFrame(() => { setActive(); ticking = false; });
      ticking = true;
    }
  }, { passive: true });
  setActive();
})();
