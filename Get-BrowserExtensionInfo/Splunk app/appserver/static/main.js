//
// This file is loaded for every dashboard.
//

//
// Enable auto-discovery
// Auto-discovery is an advanced technique for re-using custom components, especially views, in multiple dashboards and apps.
// Auto-discovery traverses the DOM to find splunk-view or splunk-manager class elements.
// The splunkjs/ready script needs to be loaded to perform auto-discovery.
// Note: the splunkjs/ready! loader script should not be loaded before the dashboard finishes rendering. This can be ensured by loading it within a splunkjs/mvc/simplexml/ready! loader script callback.
//
require.config ({
    paths: {
        "apppathUXM": "../app/uberAgent",
        "apppathESA": "../app/uberAgent_ESA"
    }
});

require (['splunkjs/mvc/simplexml/ready!'], function ()
{
   require (['splunkjs/ready!'], function ()
   {
   });
});
