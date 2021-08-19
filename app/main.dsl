context
{
  input endpoint: string;
  dasha_hello: boolean = false;
  day_of_week: string? = null;
  google_calendar_duration: string? = null;
  google_calendar_time: string? = null;
  google_calendar_title: string? = null;
}

/*
google_calendar_book - для бронирования времени Эвента (event) в гугл календаре
day_of_week - день недели, может принимать значения "monday", "thursday", "wednesday"и т.п.
time_hour - время начала эвента в часах
time_duration - длительность эвента в часах
title - заголовок эвента
Результаты на возврат: 
- успешно создано - эвент успешно создан т.е. не пересекался с другими эвентами. Значение к возврату "success"
- эвент пересекается с другими эвентами Значение к возврату "fail_cross"
*/

external function google_calendar_book (day_of_week: string, time_hour: number, time_duration: number, title: string): string;


/*
invite - для приглашения в голосовой канал, где находится бот
friend - имя пользователя, которого хочу пригласить в канал
Результаты на возврат: 
- человек приглашен Значение к возврату "invited"
- любая другая ошибка Значение к возврату "invite_failed"
*/
external function invite (friend: string): string;



start node root
{
  do
  {
    #connect($endpoint);
    #sayText("Привет, я тут Привет, я тут");
    wait *;
  }
  
  transitions
  {
  //  next: goto Next on true;
  }
}

digression dasha_hello
{
  conditions
  {
    on #messageHasIntent("dasha");
  }
  do
  {
    #sayText("Слушаю");
    set $dasha_hello = true;
    wait *;
  }
  transitions
  {
    transition0: goto google_calendar_date on #messageHasIntent("booking");
    transition1: goto invite on #messageHasIntent("invite");
  }
}

node invite
{
  do
  {
    digression disable {dasha_hello};
    #sayText("Кого пригласить?");
    wait *;
  }
  
  transitions
  {
transition0: goto friends on #messageHasData("friends");
  }
}

node friends
{
  do
  {
    wait *;
    goto transition0;

  }
  
  transitions
  {
    transition0: goto root;
  }
}

node google_calendar_date
{
  do
  {
    digression disable {dasha_hello};
    #sayText("На какой день недели?");
    wait *;
  }
  
  transitions
  {
transition0: goto google_calendar_time on #messageHasData("day_of_week");
  }
}

node google_calendar_time
{
  do
  {
    set $day_of_week = #messageGetData("day_of_week")[0]?.value;
    #sayText("На какое время?");
    wait *;
  }
  
  transitions
  {
transition0: goto google_calendar_duration on #messageHasData("time_hour");
  }
}

node google_calendar_duration
{
  do
  {
    set $google_calendar_time = #messageGetData("time_hour")[0]?.value;
    #sayText("Какая длительность разговора?");
    wait *;
  }
  
  transitions
  {
transition0: goto google_calendar_title on #messageHasData("time_hour");
  }
}

node google_calendar_title
{
  do
  {
    set $google_calendar_duration = #messageGetData("time_hour")[0]?.value;
    #sayText("Какой заголовок?");
    wait *;
  }
  
  transitions
  {
transition0: goto google_calendar_approv on true;

  }
  onexit
    {
        transition0: do
        {
            set $google_calendar_title = #getMessageText();
        }
    }
}


node google_calendar_approv
{
  do
  {
    #sayText("Давайте сверимся, я создаю событие в календаре на");
    #say("google_calendar_approv",
    {
    day_of_week: $day_of_week, 
    google_calendar_time: $google_calendar_time, 
    google_calendar_duration: $google_calendar_duration,
    google_calendar_title: $google_calendar_title
    });
    wait *;
  }
  transitions
  {
    next: goto google_calendar_approv on #messageHasIntent("bookingg");
  }
}


/*
node Next
{
  do
  {
    #sayText("Вы сказали " + #getMessageText());
    wait *;
  }
  
  transitions
  {
    next: goto Next on true;
  }
}
*/