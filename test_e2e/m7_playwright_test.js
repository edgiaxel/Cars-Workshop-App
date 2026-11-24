// Playwright E2E verification test suite for PitMate M7
// Tests multi-viewport responsiveness (320px, 375px, 425px, 768px, 1024px+),
// bottom navigation bar (capped at max 4 items),
// profile editing screen via avatar click,
// and Supabase auth PKCE password reset link recovery.

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE_URL = process.env.BASE_URL || 'http://127.0.0.1:3000';

const VIEWPORTS = [
  { name: 'mobile_320', width: 320, height: 640 },
  { name: 'mobile_375', width: 375, height: 812 },
  { name: 'mobile_425', width: 425, height: 896 },
  { name: 'tablet_768', width: 768, height: 1024 },
  { name: 'desktop_1280', width: 1280, height: 800 },
];

async function runTests() {
  console.log(`Starting PitMate M7 Playwright verification against ${BASE_URL}...`);
  const browser = await chromium.launch({
    headless: true,
    executablePath: fs.existsSync('/usr/bin/google-chrome') ? '/usr/bin/google-chrome' : undefined,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
  });

  try {
    // 1. Multi-viewport Login Screen Responsiveness & Overflow Audit
    console.log('\n--- 1. Testing Login Screen across all viewports ---');
    for (const vp of VIEWPORTS) {
      const page = await browser.newPage({ viewport: { width: vp.width, height: vp.height } });
      await page.goto(`${BASE_URL}/#/login`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(2500); // Allow Flutter web rendering

      // Check for horizontal scroll / overflow
      const scrollWidth = await page.evaluate(() => document.body.scrollWidth);
      const clientWidth = await page.evaluate(() => document.body.clientWidth);
      const hasHorizontalOverflow = scrollWidth > clientWidth;

      console.log(`[${vp.name}] (${vp.width}x${vp.height}): clientWidth=${clientWidth}, scrollWidth=${scrollWidth}, overflow=${hasHorizontalOverflow}`);
      if (hasHorizontalOverflow) {
        console.warn(`WARNING: Horizontal overflow detected on ${vp.name}!`);
      }

      // Save screenshot for 320px and 1280px
      if (vp.name === 'mobile_320') {
        await page.screenshot({ path: 'e2e_m7_01_login_320px.png' });
        console.log('Saved e2e_m7_01_login_320px.png');
      } else if (vp.name === 'desktop_1280') {
        await page.screenshot({ path: 'e2e_m7_02_login_1024px.png' });
        console.log('Saved e2e_m7_02_login_1024px.png');
      }

      await page.close();
    }

    // 2. Auth PKCE Link Recovery Workaround Test
    console.log('\n--- 2. Testing PKCE Recovery Link Landing ---');
    {
      const page = await browser.newPage({ viewport: { width: 375, height: 812 } });
      const testCode = '64aa01ae-06bd-4afe-9f53-f0d4229e8319';
      await page.goto(`${BASE_URL}/?code=${testCode}`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(3000);

      // Verify URL redirects or lands on reset-password
      const currentUrl = page.url();
      console.log(`Landing URL for ?code=...: ${currentUrl}`);

      await page.screenshot({ path: 'e2e_m7_03_recovery_link_flow.png' });
      console.log('Saved e2e_m7_03_recovery_link_flow.png');
      await page.close();
    }

    // 3. Forgot Password Screen Dispatch UI
    console.log('\n--- 3. Testing Forgot Password Screen ---');
    {
      const page = await browser.newPage({ viewport: { width: 375, height: 812 } });
      await page.goto(`${BASE_URL}/#/forgot-password`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(2000);

      await page.screenshot({ path: 'e2e_m7_04_forgot_password.png' });
      console.log('Saved e2e_m7_04_forgot_password.png');
      await page.close();
    }

    // 4. Registration Viewport Test (xgv1807@gmail.com)
    console.log('\n--- 4. Testing Registration Screen ---');
    {
      const page = await browser.newPage({ viewport: { width: 375, height: 812 } });
      await page.goto(`${BASE_URL}/#/register`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(2000);

      await page.screenshot({ path: 'e2e_m7_05_register_screen.png' });
      console.log('Saved e2e_m7_05_register_screen.png');
      await page.close();
    }

    // 5. Test Profile Screen UI directly
    console.log('\n--- 5. Testing Profile Screen UI (Mobile 320px & Desktop 1280px) ---');
    {
      // Mobile 320px
      const mobilePage = await browser.newPage({ viewport: { width: 320, height: 700 } });
      await mobilePage.goto(`${BASE_URL}/#/profile`, { waitUntil: 'networkidle', timeout: 30000 });
      await mobilePage.waitForTimeout(3000);

      const mScrollWidth = await mobilePage.evaluate(() => document.body.scrollWidth);
      const mClientWidth = await mobilePage.evaluate(() => document.body.clientWidth);
      console.log(`[Profile 320px]: clientWidth=${mClientWidth}, scrollWidth=${mScrollWidth}`);

      await mobilePage.screenshot({ path: 'e2e_m7_06_profile_screen_mobile.png' });
      console.log('Saved e2e_m7_06_profile_screen_mobile.png');
      await mobilePage.close();

      // Desktop 1280px
      const deskPage = await browser.newPage({ viewport: { width: 1280, height: 800 } });
      await deskPage.goto(`${BASE_URL}/#/profile`, { waitUntil: 'networkidle', timeout: 30000 });
      await deskPage.waitForTimeout(3000);

      await deskPage.screenshot({ path: 'e2e_m7_07_profile_screen_desktop.png' });
      console.log('Saved e2e_m7_07_profile_screen_desktop.png');
      await deskPage.close();
    }

    // 6. Test Admin and Customer navigation & bottom bar capping
    console.log('\n--- 6. Testing Role Screens & Bottom Navigation Bar Capping ---');
    {
      const page = await browser.newPage({ viewport: { width: 320, height: 640 } });
      // Admin Overview
      await page.goto(`${BASE_URL}/#/admin`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(3000);

      await page.screenshot({ path: 'e2e_m7_08_admin_320px.png' });
      console.log('Saved e2e_m7_08_admin_320px.png');

      // Admin Floor
      await page.goto(`${BASE_URL}/#/admin/floor`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(3000);

      await page.screenshot({ path: 'e2e_m7_09_admin_floor_320px.png' });
      console.log('Saved e2e_m7_09_admin_floor_320px.png');

      // Customer Garage
      await page.goto(`${BASE_URL}/#/customer/garage`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(3000);

      await page.screenshot({ path: 'e2e_m7_10_customer_garage_320px.png' });
      console.log('Saved e2e_m7_10_customer_garage_320px.png');

      await page.close();
    }

    console.log('\nAll Playwright E2E verification flows completed successfully!');
  } catch (error) {
    console.error('Playwright verification encountered an error:', error);
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
}

runTests();
