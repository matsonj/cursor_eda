# Places OS Data Schemas

## Overview

With Foursquare's Open Source Places, you can access free data to accelerate geospatial innovation and insights.

If you're interested in accessing additional attributes, please see our Places Pro & Premium Data Schemas.

## Places Dataset

| Column Name           | Type           | Description |
|----------------------|----------------|-------------|
| fsq_place_id         | String         | The unique identifier of a Foursquare POI (formerly known as venueid or fsq_id). Use this ID to view a venue at foursquare.com by visiting: http://www.foursquare.com/v/{fsq_place_id} |
| name                 | String         | Business name of a POI |
| latitude/longitude   | Decimal        | Foursquare latitudes and longitudes are delivered as decimal places (WGS84 datum), where the value does not exceed 6 decimal places. Default geocode type is front door or rooftop, where available. These are derived by a combination of: Direct input from third party sources Direct input of precise latitude/longitude (a pin drop) from initial user creation and correction |
| address              | String         | User-entered street address of the venue |
| locality             | String         | City, town or equivalent the POI is located in. |
| region               | String         | State, province, territory or equivalent. Abbreviations are used in the following countries (US, CA, AU, and BR). Remaining countries use full names. |
| postcode             | String         | Postal code of the POI, or equivalent (zip code in the US). Format will be localized based on country (i.e. 5-digit number for US postal code) |
| admin_region         | String         | Additional sub-division. Usually, but not always, a country sub-division (e.g., Scotland) |
| post_town            | String         | Town/place employed in postal addressing. May not reflect the formal geographic location of a place |
| po_box               | String         | Post Office Box |
| country              | String         | 2 Letter ISO Country Code |
| date_created         | Date           | The date the POI entered our database. This does not necessarily mean the POI actually opened on this date |
| date_refreshed       | Date           | The date the POI last had any single reference refreshed from crawl, users or human validation |
| date_closed          | Date           | The date the POI was marked as closed in our database. This does not necessarily mean the POI actually closed on this date |
| tel                  | String         | Telephone number of a POI with local formatting |
| website              | String         | URL to the POI's (or the chain's) publicly available website |
| email                | String         | Primary contact email address of organization, if available |
| facebook_id          | String         | This POI's Facebook ID, if available |
| instagram            | String         | This POI's Instagram handle, if available |
| twitter              | String         | This POI's Twitter handle, if available |
| fsq_category_ids     | Array (String) | ID (or IDs) of the most granular category (or categories) available for this POI |
| fsq_category_labels  | Array(String)  | Label (or labels) for the most granular category (or categories) available for this POI |
| placemaker_url       | string         | A link to the POI's review page in the PlaceMaker Tools application. Users can suggest edits to correct data quality issues or review pending edits |
| geom                 | wkb            | The geometry of the POI formatted as a WKB (well-known binary). This column allows the geometry to be visualized through our vector tiling service |
| bbox                 | struct         | An area defined by two longitudes and two latitudes: latitude is a decimal number between -90.0 and 90.0; longitude is a decimal number between -180.0 and 180.0.bbox:struct xmin:double ymin:double xmax:double ymax:double |

## Category Dataset

| Column Name            | Type    | Description |
|-----------------------|---------|-------------|
| category_id           | String  | The unique identifier of the Foursquare category; represented as a BSON |
| category_level        | Integer | The number of levels within the category's hierarchy; accepted values 1-6 |
| category_name         | String  | The name of the most granular category in the category hierarchy |
| category_label        | String  | The exploded category hierarchy using > to indicate category breadcrumb |
| level1_category_id    | String  | The unique identifier for the first level category in the hierarchy |
| level1_category_name  | String  | The name for the first level category in the hierarchy |
| level2_category_id    | String  | The unique identifier for the second level category in the hierarchy |
| level2_category_name  | String  | The name for the second level category in the hierarchy |
| level3_category_id    | String  | The unique identifier for the third level category in the hierarchy |
| level3_category_name  | String  | The name for the third level category in the hierarchy |
| level4_category_id    | String  | The unique identifier for the fourth level category in the hierarchy |
| level4_category_name  | String  | The name for the fourth level category in the hierarchy |
| level5_category_id    | String  | The unique identifier for the fifth level category in the hierarchy |
| level5_category_name  | String  | The name for the fifth level category in the hierarchy |
| level6_category_id    | String  | The unique identifier for the sixth level category in the hierarchy |
| level6_category_name  | String  | The name for the sixth level category in the hierarchy |

## License

Apache 2.0

Copyright 2024 Foursquare Labs, Inc. All rights reserved.
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at: http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License. 