# API: appShippingTransitEstimate




## INPUT PARAMETERS: ##
  * @products: [pid1,pid2,pid3]
  * ship_postal: 92012
  * ship_country: US

> NOTE:
> 

## RESPONSE: ##
  * : 

                           {
                             'arrival_time' => '23:00:00',
                             'amzcc' => 'UPS',
                             'UPS.Service.Description' => 'UPS Ground',
                             'UPS.EstimatedArrival.DayOfWeek' => 'TUE',
                             'carrier' => 'UPS',
                             'expedited' => '0',
                             'UPS.Guaranteed' => 'Y',
                             'method' => 'UPS Ground',
                             'code' => 'UGND',
                             'ups' => 'GND',
                             'arrival_date' => '20120715',
                             'amzmethod' => 'UPS Ground',
                             'buycomtc' => '1',
                             'upsxml' => '03',
                             'UPS.EstimatedArrival.PickupDate' => '2012-07-10',
                             'transit_days' => 5
                           } 

  * : which day the order is expected to ship (not arrive)
  * : hour and minute (pst) that the order must be placed by
  * : maximum days before order ships
