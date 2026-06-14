---
layout: post
title: "Feet on Street app"
subtitle: "A field-sales app for Amazon Distribution"
date: 2019-02-19
company: "Amazon Distribution"
image: "fos-app/hero-image.png"
description: "A mobile app designed from scratch to help field-sales teams manage retailer tasks, reconcile invoices, and unblock retailer credit faster."
---

<section class="section-bottom-margin">
  <h3>The challenge</h3>
  <p>
    Amazon Distribution connected FMCG brands, partners, and retailers, but the field-sales experience still depended on manual follow-ups, paper invoices, and delayed credit reconciliation. The central question was: how might we provide a better service to retailers while helping field teams work with more clarity?
  </p>
</section>

<section class="section-bottom-margin">
  <h3>My role</h3>
  <p>
    I designed the mobile app from scratch, covering user research, design vision, interaction design, visual design, prototyping, usability testing, leadership presentations, and product ideas.
  </p>
</section>

<section class="section-bottom-margin">
  <h3>Context</h3>
  <p>
    Amazon Distribution was an online wholesale shopping experience for categories like home, kitchen, office, stationery, grocery, health, and personal care. FMCG brands used Amazon's scale to reach retailers, while partners handled last-mile delivery and retailer credit.
  </p>
  <p>
    The field team sat in the middle of this ecosystem. They needed to plan visits, collect payments, reconcile invoices, and help retailers place the next order without carrying a stack of physical paperwork.
  </p>
</section>

<section class="section-bottom-margin">
  <h3>Research</h3>
  <p>
    To understand the operational gaps, I interviewed 8 stakeholders across product, sales, operations, marketing, and technology. I also spent time with 2 partners, 15 sales executives, 12 retailers, and 5 team leads to observe the work as it happened on the ground.
  </p>
  <p>
    The research made one thing very clear: the product had to improve both retailer trust and field-team efficiency. A better retailer experience would not come from one isolated screen; it needed a tighter operating loop across planning, ordering, delivery, and reconciliation.
  </p>
</section>

<section class="section-bottom-margin">
  <h3>Retailer journey map</h3>
  <p>
    I mapped the retailer journey across four phases: planning, ordering, delivery, and reconciliation. This helped the team see where delays, trust gaps, and manual work were affecting the overall service experience.
  </p>
  {% include retailer-journey-map.html %}
</section>

<section class="section-bottom-margin">
  <h3>Key customer problems</h3>
  <h4>1. Credit unblocking</h4>
  <p>
    The biggest pain point was credit unblocking. Retailers could pay for invoices, but still had to wait 1-2 days for their credit limit to be updated before placing another order. That wait time slowed sales for the business and created frustration for retailers who were ready to buy.
  </p>
  <h4>2. Invoice reconciliation</h4>
  <p>
    Invoice reconciliation was another recurring issue. Retailers often struggled to connect payments, invoices, and order history. The field team needed a way to make collection reporting more trustworthy and less dependent on physical documents.
  </p>
  <h4>3. Trust issues</h4>
  <p>
    BDOs sometimes present a duplicate invoice and ask for payment.
  </p>
</section>

<section class="section-bottom-margin">
  <h3>Retailer benefit</h3>
  <p>
    The most important benefit was speed. Instead of waiting 1-2 days after payment, retailers could order products again as soon as payment was reported and credit was unblocked.
  </p>
</section>

<section class="section-bottom-margin">
  <h3>Design direction</h3>
  <p>
    From a design point of view, the app needed to make field work feel structured, trustworthy, and quick to act on. The direction was to give business development officers a task-first experience where every day's work was visible: which retailers to visit, which invoices to collect, what had been reported, and where action was still pending.
  </p>
  {% include fos-goals.html %}
  <p>
    Keeping these goals in mind, the design direction focused on three principles: start from the field team's actual workflow, support scale across a large distributed operation, and keep each interaction simple enough to use during store visits.
  </p>
</section>

<section class="section-bottom-margin">
  <h4>1. Easy management for BDOs</h4>
  <div class="case-study-split case-study-split--image-right">
    <div class="case-study-split__content">
      <p>
        The home experience made the day's tasks scannable. Field executives could see collections, pending actions, and retailer-specific work without needing to maintain a separate paper trail.
      </p>
      <ul>
        <li>No need to manage excel sheets</li>
        <li>Additional retailer info to reach retailers with confidence</li>
        <li>Clear picture of the tasks to do in a day</li>
      </ul>
    </div>
    <figure class="case-study-split__media">
      <img src="{{ '/assets/img/fos-app/mobile-home.png' | prepend: site.baseurl }}" alt="Feet on Street mobile home screen showing BDO beat tasks" />
    </figure>
  </div>
  <h4>2. Scalable retailer details page</h4>
  <div class="case-study-split case-study-split--image-right case-study-split--design-step">
    <div class="case-study-split__content">
      <p>
        The retailer details page became the operational hub for each outlet visit, keeping the actions a BDO needs today visible while leaving space for future brand-specific pitch targets.
      </p>
      <ul>
        <li>Primary actions are clear: take an order or collect due payments.</li>
        <li>Retailer context and future brand targets can live on the same scalable page.</li>
        <li>The store closed action captures location so the business can verify outlet visits.</li>
      </ul>
    </div>
    <figure class="case-study-split__media">
      <img src="{{ '/assets/img/fos-app/mobile-dp.png' | prepend: site.baseurl }}" alt="Retailer details screen showing pending collection and retailer context" />
    </figure>
  </div>
  <h4>3. Easy invoice reconciliation</h4>
  <div class="case-study-split case-study-split--image-right case-study-split--design-step">
    <div class="case-study-split__content">
      <p>
        The reconciliation flow gave BDOs the context and controls to resolve payment conversations while they were still at the retailer outlet.
      </p>
      <ul>
        <li>Credit limit and usage are visible, helping BDOs decide when a retailer may need an extension.</li>
        <li>Partial payments can be collected without waiting for the full due amount.</li>
        <li>Invoices can be closed in advance when required by updating the delivery date.</li>
      </ul>
    </div>
    <figure class="case-study-split__media">
      <img src="{{ '/assets/img/fos-app/mobile-collection.png' | prepend: site.baseurl }}" alt="Collection screen for matching invoices, refunds, and amount collected" />
    </figure>
  </div>
  <h4>4. OTP confirmation</h4>
  <div class="case-study-split case-study-split--image-right case-study-split--design-step">
    <div class="case-study-split__content">
      <p>
        To prevent BDOs from reporting collections without retailer confirmation, the flow requires a one-time password before the report can be submitted.
      </p>
      <ul>
        <li>BDOs need an OTP from the retailer before reporting a collection.</li>
        <li>Retailers can add family members as trusted contacts who can also receive the OTP.</li>
        <li>The confirmation step creates a clear audit trail and reduces false reporting.</li>
      </ul>
    </div>
    <figure class="case-study-split__media">
      <img src="{{ '/assets/img/fos-app/mobile-otp.png' | prepend: site.baseurl }}" alt="OTP verification screen for confirming the collection report" />
    </figure>
  </div>
</section>

<section class="section-bottom-margin">
  <h3>Business impact</h3>
  <p>
    The app improved field visibility, reduced dependency on physical paperwork, and helped teams track sales in real time.
  </p>
  {% include fos-business-impact.html %}
</section>
