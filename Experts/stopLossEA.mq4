//+------------------------------------------------------------------+
//|                                                   stopLossEA.mq4 |
//|                                                   Istvan Kosztik |
//|                                https://www.kosztik.hu/stoplossea |
//+------------------------------------------------------------------+
#include <mt4gui2.mqh>

#property copyright "Istvan Kosztik"
#property link      "https://www.kosztik.hu/stoplossea"
#property version   "2.00"
#property strict
//--- input parameters
extern int    Length=10;
extern int    ATRperiod=5;
extern double Kv=3.5;

int hwnd=0;

int Button1,Button2,Button3,panel;

int Size=0,cnt,orderType,StopLevel,flipflop=0,flipflop2=0,Size_now,pipSzorzo;
string orderSymbol;
double smin,smax,slSell,slBuy,digits,haOpenPrev,haClosePrev,haOpen,haClose;

// Settings
int GUIX = 50;
int GUIY = 100;
int GUIX2 = 50;
int GUIY2 = 200;
int GUIX3 = 50;
int GUIY3 = 150;
int ButtonWidth=150;
int ButtonHeight=30;

bool robotMode=False;
bool robotModeActivated=False;
bool robotModeWasWarned=False;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   digits=MarketInfo(orderSymbol,MODE_DIGITS);

   ObjectsDeleteAll();
   hwnd=WindowHandle(Symbol(),Period());
// Lets remove all Objects from Chart before we start
   guiRemoveAll(hwnd);
// Lets build the Interface
   BuildInterface();
   return(0);
//---

  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
// Very important to cleanup and remove all gui items from chart      
   if(hwnd>0) { guiRemoveAll(hwnd);     guiCleanup(hwnd); }

  }
//+------------------------------------------------------------------+
//| tp meghatározása. Itt nem lesz konkrét tp beállítva, csak a prg figyeli                                                                  |
//+------------------------------------------------------------------+
void tpSet()
  {
   int Size2=OrdersTotal();
   for(int cnt2=0;cnt2<Size2;cnt2++)
     {
      OrderSelect(cnt2,SELECT_BY_POS,MODE_TRADES);
      int orderType2=OrderType(); // megnézem a tipusát, az sl beállítása végett
      string orderSymbol2=OrderSymbol(); // DEvizapár
      double haOpenPrev=NormalizeDouble(iCustom(orderSymbol,PERIOD_M15,"Heiken_Ashi_Smoothed",0,5,1),5);
      double haClosePrev=NormalizeDouble(iCustom(orderSymbol,PERIOD_M15,"Heiken_Ashi_Smoothed",0,6,1),5);
      double haOpen=NormalizeDouble(iCustom(orderSymbol,PERIOD_M15,"Heiken_Ashi_Smoothed",0,5,0),5);
      double haClose=NormalizeDouble(iCustom(orderSymbol,PERIOD_M15,"Heiken_Ashi_Smoothed",0,6,0),5);

      Print(orderSymbol2,",",orderType2,": ",haOpenPrev,"/",haClosePrev);
      // most megvizsgáljuk a jelenlegi trade-t
      if(orderType2==OP_BUY)
        {
         // ha buy, akkor úgy kell kilépni, ha az elõzõ HA gyertya már csökkenõ volt
         if(haOpenPrev<haClosePrev && haOpen<haClose)

           {            // az elõzõ HA gyertya piros. Zárnunk kell.
            bool res2=OrderClose(OrderTicket(),OrderLots(),Ask,3,Green);
            if(!res2)
              {
               Print(orderSymbol2,": ","Error in OrderClose. Error code=",GetLastError());
              }
            else
              {
               Print("Order modified successfully.");
              }
           }
        }
      if(orderType2==OP_SELL)
        {

         // ha sell, akkor úgy kell kilépni, ha az elõzõ HA gyertya növekvõ volt.
         if(haOpenPrev>haClosePrev && haOpen>haClose)
           {
            // az elõzõ HA gyertya zöld. Zárnunk kell.
            bool res2=OrderClose(OrderTicket(),OrderLots(),Bid,3,Green);
            if(!res2)
              {
               Print(orderSymbol2,": ","Error in OrderClose. Error code=",GetLastError());
              }
            else
              {
               Print("Order modified successfully.");
              }
           }
        }

     }

  }
//+------------------------------------------------------------------+
//| Expert setting stop loss based on ATR indicator                                             |
//+------------------------------------------------------------------+
void slSet()
  {
   Size=OrdersTotal();
   for(int cnt=0;cnt<Size;cnt++)
     {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      orderType=OrderType(); // megnézem a tipusát, az sl beállítása végett
      orderSymbol=OrderSymbol(); // DEvizapár
      StopLevel=MarketInfo(orderSymbol,MODE_STOPLEVEL)+MarketInfo(orderSymbol,MODE_SPREAD);
/*
    
         OP_BUY  0
	      OP_SELL 1
	   
	      csak ezzel a kettõ értékkel foglalkozom, semmilyen más tipussal.
    */
      if(orderType==OP_BUY)
        {

         slBuy=MathMax(iHigh(orderSymbol,PERIOD_M15,1)-Kv*iATR(orderSymbol,0,ATRperiod,1),iHigh(orderSymbol,PERIOD_M15,2)-Kv*iATR(orderSymbol,0,ATRperiod,2));
         // MathMax( smin[shift], High[shift+i] - Kv*iATR(NULL,0,ATRperiod,shift+i)); 
         // if (atrstop < StopLevel) slBuy = StopLevel

         Print("Market: ",StopLevel,", ATRsL: ",Kv,", ",iATR(orderSymbol,0,ATRperiod,1),", ",Kv*iATR(orderSymbol,0,ATRperiod,1));
         // Print (StopLevel,", ", High[1] - Kv*iATR(orderSymbol,0,ATRperiod,1));

         bool res=OrderModify(OrderTicket(),OrderOpenPrice(),slBuy,OrderTakeProfit(),0,Blue);
         if(!res)
           {
            Print(orderSymbol,": ","Error in OrderModify. Error code=",GetLastError());
           }
         else
           {
            Print("Order modified successfully.");
           }
        }

      if(orderType==OP_SELL)
        {

         slSell=MathMin(iLow(orderSymbol,PERIOD_M15,2)+Kv*iATR(orderSymbol,0,ATRperiod,2),iLow(orderSymbol,PERIOD_M15,1)+Kv*iATR(orderSymbol,0,ATRperiod,1));
         //  MathMin( smax[shift], Low[shift+i] + Kv*iATR(NULL,0,ATRperiod,shift+i));
         bool res=OrderModify(OrderTicket(),OrderOpenPrice(),slSell,OrderTakeProfit(),0,Red);
         if(!res)
           {
            Print(orderSymbol,": ","Error in OrderModify. Error code=",GetLastError());
           }
         else
           {
            Print("Order modified successfully.");
           }
        }
     }

  }
//+------------------------------------------------------------------+
//| Expert function                                             |
//+------------------------------------------------------------------+
void BuildInterface()
  {
   Button1=guiAdd(hwnd,"button",GUIX,GUIY+ButtonHeight*1+5,220,ButtonHeight,"Itt vagyok!");
   guiSetBgColor(hwnd,Button1,Red);

   Button2=guiAdd(hwnd,"button",GUIX2,GUIY2+ButtonHeight*1+5,220,ButtonHeight,"Robot! Most!");
   guiSetBgColor(hwnd,Button1,Red);

   Button3=guiAdd(hwnd,"button",GUIX3,GUIY3+ButtonHeight*1+5,220,ButtonHeight,"Ellenorzés!");
   guiSetBgColor(hwnd,Button1,Red);
  }
//+------------------------------------------------------------------+
//| give the pips of profit                                                               |
//+------------------------------------------------------------------+
double pips()
  {

   double pips;
   OrderSelect(0,SELECT_BY_POS,MODE_TRADES);

   if(OrderType()==OP_BUY)
     {
      pips=(Bid-OrderOpenPrice())*100000;

     }

   if(OrderType()==OP_SELL)
     {
      pips=(OrderOpenPrice()-Ask)*100000;

     }

   return NormalizeDouble(pips, 15);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   int min,sec;

   min = Time[0] + PERIOD_M15*60 - CurTime();
   sec = min%60;
   min=(min-min%60)/60; // idõszámítások, hogy pontosan tudjam mikor van 15. perc

   Size_now= OrdersTotal();
   if(Size!=Size_now) slSet();  // ha új pozi van, akkor annak nyomban beállítjuk az sl-t
                                // így nem kell várni a köv. 15. percre. 
/*
                                    itt lesz egy probléma: ez az sl beállítás hiba miatt nem mindig történik meg
                                    gondolom az sl túl közel van a price-hoz, vagy az atr kalkulált sl
                                    nem esik jó helyre nagy mozgás után. 
                                    
                                    módosítani kellene az slSet fg.-t úgy, ha valami hibára fut, akkor valami 
                                    alapértelmezettet állítson be.
                                */

   if(min!=14) flipflop=0;

   if(min==14 && flipflop==0)
     { // csak minden 15. percben fut le egyszer és kezdeményezi a robot módot
      // Ez a normális, robot mód mentes mód :)
      flipflop=1;
      // slSet(); // mégsem itt állítom az sl-t autómatikusan, hanem azt átteszem a robot módba!
      guiSetBgColor(hwnd,Button1,Red);
      if(!robotMode) robotMode=True;

     }

   if(guiIsClicked(hwnd,Button3))
     {
      tpSet();
      //slSet();
     }

   if(guiIsClicked(hwnd,Button2))
     {
      robotMode=True;
      robotModeActivated=True;
      robotModeWasWarned= True;
     }
   if(guiIsClicked(hwnd,Button1))
     { // ha a gombra kattintok akkor a robot mód leáll, és visszaugrik minden normál módra
      guiSetBgColor(hwnd,Button1,Green);
      robotMode=False;
      robotModeActivated=False;
      robotModeWasWarned= False;
      guiSetText(hwnd,Button1,"Itt vagyok!",0,"");
     }

   if(robotMode && robotModeWasWarned==False && min==12 && robotModeActivated==False)
     {
      // kivárok még 2 percet, hátha meg lesz nyomva a gomb
      // ha nem aktivizálódik a robot mód

      robotModeWasWarned=True;
      Alert("Egy perc és robotMódba lépek");

     }

   if(robotMode && min==11 && robotModeActivated==False)
     {
      // robot módba léptem

      robotModeActivated=True;

     }

   if(robotModeActivated)
     { // és ez a robot mód kódja
      // itt is csinálok egy 15 percenkénti ellenõrzést és ebben a módban állítom az SL-t.
      guiSetText(hwnd,Button1,"Aktív robot mód! ["+Ask+"]",0,"");

      if(min!=14) flipflop2=0;
      if(min==14 && flipflop2==0)
        { // csak minden 15. percben fut 

         flipflop2=1;

         tpSet();
         slSet();

        }

      // Robotmódban meghatározom a TP-t
      // kilépésre a 
      // setTP

      // ill, benne lesz a +pips védelem is. 
      // pipProtect

      // végigmegyek minden kereskedésen és a pips() függvénnyel megvizsgálom az értéket
      // Ha ez eléri a beállítottat, akkor a a tömbbe bejegyzem, hogy az a kereskedés nulla pip esetén lezárandó!
      // de hogy nézzen ki a tömb ?

     }

  }
//+------------------------------------------------------------------+
