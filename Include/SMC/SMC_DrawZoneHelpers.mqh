// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWZONEHELPERS_MQH
#define SMC_DRAWZONEHELPERS_MQH

int SMC_ZoneZOrder(const string objectName)
{
   if(StringFind(objectName,"PL_")>=0)
      return -50;
   if(StringFind(objectName,"PD_")>=0)
      return -40;
   if(StringFind(objectName,"FVG_")>=0)
      return -30;
   if(StringFind(objectName,"OB_")>=0)
      return -20;
   if(StringFind(objectName,"STR_")>=0)
      return 0;
   if(StringFind(objectName,"SW_")>=0)
      return 0;
   return -10;
}

double SMC_LabelOffsetPrice(const string objectName,const double basePrice,
                            const double span)
{
   double step=MathMax(0.000001,MathAbs(span)*0.08);
   if(StringFind(objectName,"OB_")==0)
      return basePrice+step;
   if(StringFind(objectName,"FVG_")==0)
      return basePrice+step*0.5;
   if(StringFind(objectName,"PD_")==0)
      return basePrice+step*0.75;
   return basePrice;
}

bool SMC_ZoneRectanglesOverlap(const datetime leftA,const datetime rightA,
                               const double topA,const double bottomA,
                               const datetime leftB,const datetime rightB,
                               const double topB,const double bottomB)
{
   if(rightA<=leftB || rightB<=leftA)
      return false;
   double highA=MathMax(topA,bottomA);
   double lowA=MathMin(topA,bottomA);
   double highB=MathMax(topB,bottomB);
   double lowB=MathMin(topB,bottomB);
   return !(highA<=lowB || highB<=lowA);
}

#endif // SMC_DRAWZONEHELPERS_MQH
