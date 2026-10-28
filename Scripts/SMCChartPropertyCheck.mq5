// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#property strict

#include <SMC/SMC_Draw.mqh>

int CheckCount=0;
int FailCount=0;

void PropertyCheck(const bool ok,const string name)
{
   if(ok)
   {
      CheckCount++;
      PrintFormat("SMC_DRAW_CHECK PASS: %s",name);
   }
   else
   {
      FailCount++;
      PrintFormat("SMC_DRAW_CHECK FAIL: %s",name);
   }
}

void CleanupTestObjects(const string prefix)
{
   DeleteObjectsWithPrefix(prefix);
}

void OnStart()
{
   CheckCount=0;
   FailCount=0;
   const string prefix="SMC_AUTOTEST_DRAW_";
   datetime now=TimeCurrent();
   CleanupTestObjects(prefix);

   DrawZoneBox(prefix+"ValidZone",now-PeriodSeconds(_Period)*20,now+PeriodSeconds(_Period)*20,
              105.0,95.0,(color)0x089981);
   string zone=prefix+"ValidZone";
   PropertyCheck(ObjectFind(0,zone)>=0,"valid rectangle is created");
   PropertyCheck(ObjectGetInteger(0,zone,OBJPROP_TYPE)==OBJ_RECTANGLE,
                 "rectangle uses OBJ_RECTANGLE");
   PropertyCheck(ObjectGetInteger(0,zone,OBJPROP_FILL)!=0,
                 "rectangle fill is enabled");
   PropertyCheck(ObjectGetInteger(0,zone,OBJPROP_BACK)!=0,
                 "rectangle is sent to background so candles remain visible");
   PropertyCheck(ObjectGetInteger(0,zone,OBJPROP_ZORDER)==-1,
                 "rectangle z-order keeps it behind chart elements");
   PropertyCheck(((uint)ObjectGetInteger(0,zone,OBJPROP_COLOR)&0xFFFFFF)==0x089981,
                 "rectangle color is stored as RGB without an ARGB black fill");

   DrawText(prefix+"ValidLabel",now,100.0,"Equilibrium",clrWhite,ANCHOR_CENTER);
   string label=prefix+"ValidLabel";
   PropertyCheck(ObjectFind(0,label)>=0,"center label is created");
   PropertyCheck(ObjectGetInteger(0,label,OBJPROP_TYPE)==OBJ_TEXT,
                 "label uses OBJ_TEXT");
   PropertyCheck(ObjectGetInteger(0,label,OBJPROP_ANCHOR)==ANCHOR_CENTER,
                 "label anchor is centered in the zone");
   PropertyCheck(ObjectGetInteger(0,label,OBJPROP_BACK)==0,
                 "label stays on the foreground layer");
   PropertyCheck(ObjectGetInteger(0,label,OBJPROP_ZORDER)==10,
                 "label has a foreground z-order");

   DrawZoneBox(prefix+"InvalidZone",now,now,100.0,100.0,(color)0xF23645);
   PropertyCheck(ObjectFind(0,prefix+"InvalidZone")<0,
                 "invalid zero-height geometry is deleted");

   CleanupTestObjects(prefix);
   PrintFormat("SMC_DRAW_CHECK SUMMARY: %d passed, %d failed",CheckCount,FailCount);
}
