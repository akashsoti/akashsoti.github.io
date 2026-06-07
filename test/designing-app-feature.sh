#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/designing-app-feature-jekyll.log

post="_site/blog/feet-on-street-app/index.html"
css="assets/css/overrides/case-study-text-blocks.css"

if grep -q '/assets/img/fos-app/slide-31.png' "$post"; then
  echo "Expected the first Designing the app image to be removed." >&2
  exit 1
fi

if grep -q 'Feet on Street app home screen for managing field tasks' "$post"; then
  echo "Expected the old first image alt text to be removed." >&2
  exit 1
fi

if grep -q '<h3>Designing the app</h3>' "$post"; then
  echo "Expected the old Designing the app heading to be removed." >&2
  exit 1
fi

if grep -q '<h2>Easy management for BDOs</h2>' "$post"; then
  echo "Expected the feature section title to no longer render as an h2." >&2
  exit 1
fi

if grep -q '<h4>Easy management for BDOs</h4>' "$post"; then
  echo "Expected the feature section title to become a numbered h4." >&2
  exit 1
fi

if ! grep -q '<h4>1. Easy management for BDOs</h4>' "$post"; then
  echo "Expected the first design item title to render as a numbered h4." >&2
  exit 1
fi

for text in \
  '<li>No need to manage excel sheets</li>' \
  '<li>Additional retailer info to reach retailers with confidence</li>' \
  '<li>Clear picture of the tasks to do in a day</li>'; do
  if ! grep -q "$text" "$post"; then
    echo "Expected design-support bullet '$text' to render." >&2
    exit 1
  fi
done

if ! grep -q 'class="case-study-split case-study-split--image-right"' "$post"; then
  echo "Expected the home screen feature to render as a split text/image block." >&2
  exit 1
fi

if grep -q 'class="case-study-feature-tile"' "$post"; then
  echo "Expected the former feature tile to become the section h2 instead." >&2
  exit 1
fi

if ! grep -q '/assets/img/fos-app/mobile-home.png' "$post"; then
  echo "Expected the mobile-home image to render." >&2
  exit 1
fi

if ! grep -q 'Feet on Street mobile home screen showing BDO beat tasks' "$post"; then
  echo "Expected the mobile-home image alt text to render." >&2
  exit 1
fi

if grep -q '/assets/img/fos-app/slide-35.png' "$post"; then
  echo "Expected the legacy collection slide image to be replaced by the second numbered design item." >&2
  exit 1
fi

if grep -q 'Feet on Street app invoice reconciliation and collection reporting screen' "$post"; then
  echo "Expected the legacy collection slide alt text to be removed." >&2
  exit 1
fi

if grep -q '<h4>2. Easy invoice reconciliation</h4>' "$post"; then
  echo "Expected invoice reconciliation to move to the third design item." >&2
  exit 1
fi

if ! grep -q '<h4>2. Scalable retailer details page</h4>' "$post"; then
  echo "Expected the second design item title to describe the retailer details page." >&2
  exit 1
fi

if ! grep -q '<h4>3. Easy invoice reconciliation</h4>' "$post"; then
  echo "Expected invoice reconciliation to render as the third design item." >&2
  exit 1
fi

for text in \
  'The retailer details page became the operational hub for each outlet visit, keeping the actions a BDO needs today visible while leaving space for future brand-specific pitch targets.' \
  '<li>Primary actions are clear: take an order or collect due payments.</li>' \
  '<li>Retailer context and future brand targets can live on the same scalable page.</li>' \
  '<li>The store closed action captures location so the business can verify outlet visits.</li>' \
  'The reconciliation flow gave BDOs the context and controls to resolve payment conversations while they were still at the retailer outlet.' \
  '<li>Credit limit and usage are visible, helping BDOs decide when a retailer may need an extension.</li>' \
  '<li>Partial payments can be collected without waiting for the full due amount.</li>' \
  '<li>Invoices can be closed in advance when required by updating the delivery date.</li>' \
  '<h4>4. OTP confirmation</h4>' \
  'To prevent BDOs from reporting collections without retailer confirmation, the flow requires a one-time password before the report can be submitted.' \
  '<li>BDOs need an OTP from the retailer before reporting a collection.</li>' \
  '<li>Retailers can add family members as trusted contacts who can also receive the OTP.</li>' \
  '<li>The confirmation step creates a clear audit trail and reduces false reporting.</li>'; do
  if ! grep -q "$text" "$post"; then
    echo "Expected second design item text '$text' to render." >&2
    exit 1
  fi
done

if grep -q '<h5>OTP confirmation</h5>' "$post"; then
  echo "Expected OTP confirmation title to use the numbered h4 pattern, not h5." >&2
  exit 1
fi

if grep -q '<strong>OTP confirmation.</strong> OTP verification adds a clear retailer confirmation moment before the collection is reported.' "$post"; then
  echo "Expected the old OTP paragraph to be replaced by a title, paragraph, and bullets." >&2
  exit 1
fi

if grep -q '<strong>Invoice collection.</strong> The collection screen keeps invoices, refunds, and amount collected together so the BDO can reconcile without switching records.' "$post"; then
  echo "Expected the old invoice collection paragraph to be replaced by refined bullets." >&2
  exit 1
fi

for image in mobile-dp.png mobile-collection.png mobile-otp.png; do
  if ! grep -q "/assets/img/fos-app/$image" "$post"; then
    echo "Expected $image to render as an individual invoice reconciliation image." >&2
    exit 1
  fi
done

if grep -q '<strong>Collection success.</strong>' "$post"; then
  echo "Expected the collection success section text to be removed." >&2
  exit 1
fi

if grep -q '/assets/img/fos-app/mobile-sc.png' "$post"; then
  echo "Expected the collection success image to be removed." >&2
  exit 1
fi

if grep -q 'case-study-phone-grid' "$post"; then
  echo "Expected invoice reconciliation images to be separate split rows, not one phone grid." >&2
  exit 1
fi

design_step_count=$(grep -o 'case-study-split case-study-split--image-right case-study-split--design-step' "$post" | wc -l | tr -d ' ')
if [[ "$design_step_count" != "3" ]]; then
  echo "Expected three separate design split rows after the first item, found $design_step_count." >&2
  exit 1
fi

tile_line=$(grep -n -m1 '1. Easy management for BDOs' "$post" | cut -d: -f1)
bullet_line=$(grep -n -m1 'Clear picture of the tasks to do in a day' "$post" | cut -d: -f1)
image_line=$(grep -n -m1 '/assets/img/fos-app/mobile-home.png' "$post" | cut -d: -f1)
second_title_line=$(grep -n -m1 '2. Scalable retailer details page' "$post" | cut -d: -f1)
retailer_text_line=$(grep -n -m1 'The retailer details page became the operational hub' "$post" | cut -d: -f1)
retailer_bullet_line=$(grep -n -m1 'The store closed action captures location' "$post" | cut -d: -f1)
third_title_line=$(grep -n -m1 '3. Easy invoice reconciliation' "$post" | cut -d: -f1)
collection_text_line=$(grep -n -m1 'The reconciliation flow gave BDOs the context and controls' "$post" | cut -d: -f1)
collection_bullet_line=$(grep -n -m1 'Invoices can be closed in advance' "$post" | cut -d: -f1)
otp_title_line=$(grep -n -m1 '<h4>4. OTP confirmation</h4>' "$post" | cut -d: -f1)
otp_text_line=$(grep -n -m1 'To prevent BDOs from reporting collections without retailer confirmation' "$post" | cut -d: -f1)
otp_bullet_line=$(grep -n -m1 'The confirmation step creates a clear audit trail' "$post" | cut -d: -f1)
mobile_dp_line=$(grep -n -m1 '/assets/img/fos-app/mobile-dp.png' "$post" | cut -d: -f1)
mobile_collection_line=$(grep -n -m1 '/assets/img/fos-app/mobile-collection.png' "$post" | cut -d: -f1)
mobile_otp_line=$(grep -n -m1 '/assets/img/fos-app/mobile-otp.png' "$post" | cut -d: -f1)

if [[ -z "$tile_line" || -z "$bullet_line" || -z "$image_line" ]]; then
  echo "Expected title, bullets, and mobile-home image lines to exist." >&2
  exit 1
fi

if (( tile_line >= bullet_line || bullet_line >= image_line )); then
  echo "Expected title, text bullets, and then right-side image in source order." >&2
  exit 1
fi

if [[ -z "$second_title_line" || -z "$retailer_text_line" || -z "$retailer_bullet_line" || -z "$third_title_line" || -z "$collection_text_line" || -z "$collection_bullet_line" || -z "$otp_title_line" || -z "$otp_text_line" || -z "$otp_bullet_line" || -z "$mobile_dp_line" || -z "$mobile_collection_line" || -z "$mobile_otp_line" ]]; then
  echo "Expected second and third design item titles, text blocks, and mobile image lines to exist." >&2
  exit 1
fi

if (( second_title_line <= image_line || second_title_line >= retailer_text_line || retailer_text_line >= retailer_bullet_line || retailer_bullet_line >= mobile_dp_line || mobile_dp_line >= third_title_line )); then
  echo "Expected retailer details to be item two, with text and bullets before mobile-dp, before item three." >&2
  exit 1
fi

if (( third_title_line >= collection_text_line || collection_text_line >= collection_bullet_line || collection_bullet_line >= mobile_collection_line || mobile_collection_line >= otp_title_line || otp_title_line >= otp_text_line || otp_text_line >= otp_bullet_line || otp_bullet_line >= mobile_otp_line )); then
  echo "Expected invoice reconciliation rows in order: item three, refined bullets, mobile-collection, item four OTP title/text/bullets, and mobile-otp." >&2
  exit 1
fi

if ! grep -q 'width: 75%' "$css"; then
  echo "Expected desktop split block to stay within the post content width." >&2
  exit 1
fi

if ! grep -q 'margin: 0 auto 3rem' "$css"; then
  echo "Expected desktop split block to remove the extra top spacing above image and text." >&2
  exit 1
fi

if ! grep -q 'grid-template-columns: minmax(0, 1fr) minmax(220px, 0.65fr)' "$css"; then
  echo "Expected desktop split block to use text-left/image-right grid columns." >&2
  exit 1
fi

if ! grep -q 'align-items: start' "$css"; then
  echo "Expected split block text and image to align to the top." >&2
  exit 1
fi

if ! grep -q '.post .case-study-split__content ul' "$css"; then
  echo "Expected local list styling for the split block bullets." >&2
  exit 1
fi

if ! grep -q 'padding-left: 1.1rem' "$css"; then
  echo "Expected split block bullets to use a controlled marker gutter." >&2
  exit 1
fi

if ! grep -q 'list-style-position: outside' "$css"; then
  echo "Expected split block bullets to align wrapped text after the marker." >&2
  exit 1
fi

if ! grep -q '.post .case-study-split__content li' "$css"; then
  echo "Expected split block bullet items to have local spacing styles." >&2
  exit 1
fi

if grep -q '.post .case-study-split__content h5' "$css"; then
  echo "Expected obsolete scoped h5 styling to be removed once OTP uses the h4 pattern." >&2
  exit 1
fi

if ! grep -q 'text-align: left' "$css"; then
  echo "Expected split block bullets to be left-aligned." >&2
  exit 1
fi

if grep -q '.case-study-phone-grid' "$css"; then
  echo "Expected obsolete phone grid styling to be removed." >&2
  exit 1
fi

if ! grep -q '.post .case-study-split--design-step' "$css"; then
  echo "Expected repeated design split rows to have dedicated spacing styles." >&2
  exit 1
fi

if ! grep -q '.case-study-split--image-right' "$css"; then
  echo "Expected split block styling for the right-side image layout." >&2
  exit 1
fi

if ! grep -q 'grid-template-columns: 1fr' "$css"; then
  echo "Expected mobile split block to stack into a single column." >&2
  exit 1
fi

if ! grep -q 'width: 100%' "$css"; then
  echo "Expected mobile split block to use the available mobile content width." >&2
  exit 1
fi

if ! grep -q 'margin: 0 auto 2.5rem' "$css"; then
  echo "Expected mobile split block to remove the extra top spacing above image and text." >&2
  exit 1
fi
