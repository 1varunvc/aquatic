// ###############################################################################
// Script Name : mm-extract-csv
// Description : Clicks download links, waits for spinner, handles pagination.
// Author      : Varun Chawla
// Created On  : March 21, 2026
// Last Updated: March 21, 2026
// Usage       : ./aquatic snippet mm-extract-csv [downloadLinksXpath] [loadingSpinnerSelector] [nextPageButtonXpath] [delayBetweenClicks]
// ###############################################################################

(async () => {
  // --- CONFIGURATION ---
  const CONFIG = {
    downloadLinksXpath: "___DOWNLOAD_LINKS_XPATH___",
    loadingSpinnerSelector: "___SPINNER_SELECTOR___",
    nextPageButtonXpath: "___NEXT_PAGE_XPATH___",
    delayBetweenClicks: ___DELAY___,
  };

  // --- HELPER FUNCTIONS ---
  const getElementByXpath = (xpath) => {
    return document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
  };

  const getAllElementsByXpath = (xpath) => {
    const iterator = document.evaluate(xpath, document, null, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null);
    let nodes = [];
    let node = iterator.iterateNext();
    while (node) {
      nodes.push(node);
      node = iterator.iterateNext();
    }
    return nodes;
  };

  const isLoaderVisible = () => {
    const loader = document.querySelector(CONFIG.loadingSpinnerSelector);
    if (!loader) return false;
    const style = window.getComputedStyle(loader);
    return style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0';
  };

  const waitForLoader = (shouldBeVisible, maxWaitMs) => {
    return new Promise((resolve) => {
      let elapsed = 0;
      const intervalMs = 100;

      const interval = setInterval(() => {
        elapsed += intervalMs;
        const visible = isLoaderVisible();

        if (visible === shouldBeVisible) {
          clearInterval(interval);
          resolve(true);
        } else if (elapsed >= maxWaitMs) {
          clearInterval(interval);
          resolve(false);
        }
      }, intervalMs);
    });
  };

  const waitForLoaderCycle = async () => {
    // Wait max 3 seconds for loader to APPEAR
    await waitForLoader(true, 3000);
    // Wait max 60 seconds for loader to DISAPPEAR
    await waitForLoader(false, 60000);
  };

  // --- MAIN EXECUTION ---
  let hasNextPage = true;
  let pageCount = 1;

  while (hasNextPage) {
    console.log(`%c[INFO] --- Processing Page ${pageCount} ---`, "color: #4da6ff; font-weight: bold;");

    const links = getAllElementsByXpath(CONFIG.downloadLinksXpath);
    console.log(`%c[INFO] Found ${links.length} download buttons.`, "color: #a6a6a6;");

    for (let i = 0; i < links.length; i++) {
      console.log(`%c[ACTION] Downloading file ${i + 1} of ${links.length}...`, "color: #cccccc;");

      links[i].click();
      await waitForLoaderCycle();

      // Delay to ensure the browser has time to initiate the file save
      await new Promise(r => setTimeout(r, CONFIG.delayBetweenClicks));
    }

    // Pagination
    const nextBtnTarget = getElementByXpath(CONFIG.nextPageButtonXpath);

    if (nextBtnTarget) {
      const parentLi = nextBtnTarget.closest('li');
      const isDisabled =
          (parentLi && parentLi.classList.contains('disabled')) ||
          nextBtnTarget.classList.contains('disabled') ||
          nextBtnTarget.getAttribute('aria-disabled') === 'true';

      if (!isDisabled) {
        console.log(`%c[INFO] Moving to page ${pageCount + 1}...`, "color: #f2c94c;");
        nextBtnTarget.click();
        pageCount++;

        await new Promise(r => setTimeout(r, 500));
        await waitForLoaderCycle();
        await new Promise(r => setTimeout(r, 1000));
      } else {
        console.log("%c[INFO] Processing complete. Next button is disabled.", "color: #27ae60; font-weight: bold;");
        hasNextPage = false;
      }
    } else {
      console.log("%c[INFO] Processing complete. No further pages found.", "color: #27ae60; font-weight: bold;");
      hasNextPage = false;
    }
  }

  console.log("%c[SUCCESS] Script execution finished.", "color: #27ae60; font-weight: bold;");
})();