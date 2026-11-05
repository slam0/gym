#import "SLLang.h"
#import "SLStore.h"
#import "sl_core.h"

NSString *const SLAppearanceDidChangeNotification = @"SLAppearanceDidChangeNotification";

static NSInteger gLang = -1;

static NSInteger SLAutoLanguage(void)
{
    NSArray *prefs = [NSLocale preferredLanguages];
    NSString *first = [prefs count] ? [prefs objectAtIndex:0] : @"pl";
    if ([first hasPrefix:@"pl"]) return 0;
    if ([first hasPrefix:@"ru"]) return 2;
    return 1;
}

NSInteger SLLanguageSetting(void) { return [SLStore shared].languageSetting; }

NSInteger SLLanguage(void)
{
    if (gLang < 0) {
        NSInteger s = SLLanguageSetting();
        gLang = (s >= 1 && s <= 3) ? s - 1 : SLAutoLanguage();
    }
    return gLang;
}

void SLSetLanguageSetting(NSInteger setting)
{
    if (setting < 0 || setting > 3) setting = 0;
    [SLStore shared].languageSetting = setting;
    gLang = -1;
    [[NSNotificationCenter defaultCenter] postNotificationName:SLAppearanceDidChangeNotification object:nil];
}

NSString *SLLanguageSettingName(NSInteger setting)
{
    switch (setting) {
        case 1: return @"Polski";
        case 2: return @"English";
        case 3: return @"Русский";
        default: return GL(@"Automatycznie");
    }
}

NSLocale *SLLocale(void)
{
    static NSLocale *cache[3];
    NSInteger l = SLLanguage();
    if (!cache[l]) {
        NSString *ids[3] = { @"pl_PL", @"en_GB", @"ru_RU" };
        cache[l] = [[NSLocale alloc] initWithLocaleIdentifier:ids[l]];
    }
    return cache[l];
}

/* polski | angielski | rosyjski */
static const struct { NSString *pl, *en, *ru; } kStrings[] = {
    { @"Główna", @"Home", @"Главная" },
    { @"Trening", @"Workout", @"Тренировка" },
    { @"Historia", @"History", @"История" },
    { @"Ćwiczenia", @"Exercises", @"Упражнения" },
    { @"Ustawienia", @"Settings", @"Настройки" },
    { @"Twoje treningi w liczbach", @"Your training in numbers", @"Ваши тренировки в цифрах" },
    { @"Treningi", @"Workouts", @"Тренировки" },
    { @"Czas", @"Time", @"Время" },
    { @"Objętość", @"Volume", @"Объём" },
    { @"Nowy trening", @"New workout", @"Новая тренировка" },
    { @"Powtórz poprzedni trening", @"Repeat previous workout", @"Повторить прошлую тренировку" },
    { @"Zacznij pierwszy trening, a tu pojawią się twoje liczby.", @"Start your first workout and your numbers will show up here.", @"Начните первую тренировку, и здесь появятся ваши цифры." },
    { @"Wróć do treningu", @"Back to workout", @"Вернуться к тренировке" },
    { @"Masz trwający trening. Dokończ go albo zakończ w zakładce Trening.", @"You have a workout in progress. Finish it in the Workout tab.", @"У вас идёт тренировка. Завершите её на вкладке «Тренировка»." },
    { @"Poprzedni trening: %@\n%@, %@", @"Previous workout: %@\n%@, %@", @"Прошлая тренировка: %@\n%@, %@" },
    { @"Rozpocznij trening", @"Start workout", @"Начать тренировку" },
    { @"Powtórz ostatni trening", @"Repeat last workout", @"Повторить последнюю" },
    { @"Dziennik treningowy", @"Training log", @"Дневник тренировок" },
    { @"+ Dodaj ćwiczenie", @"+ Add exercise", @"+ Добавить упражнение" },
    { @"Zakończ trening", @"Finish workout", @"Завершить тренировку" },
    { @"Anuluj trening", @"Cancel workout", @"Отменить тренировку" },
    { @"Dodaj pierwsze ćwiczenie, żeby zacząć wpisywać serie.", @"Add your first exercise to start logging sets.", @"Добавьте первое упражнение, чтобы записывать подходы." },
    { @"Pomiń", @"Skip", @"Пропустить" },
    { @"Zakończ", @"Finish", @"Завершить" },
    { @"Ostatni trening: %@\n%@, %@", @"Last workout: %@\n%@, %@", @"Последняя тренировка: %@\n%@, %@" },
    { @"Jeszcze nie masz zapisanych treningów.\nDotknij „Rozpocznij trening”.", @"You have no saved workouts yet.\nTap “Start workout”.", @"У вас пока нет тренировок.\nНажмите «Начать тренировку»." },
    { @"Przerwa %@", @"Rest %@", @"Отдых %@" },
    { @"Brak wykonanych serii", @"No completed sets", @"Нет выполненных подходов" },
    { @"Zaznacz serie jako zrobione (ptaszek po prawej) albo usuń ten trening.", @"Mark sets as done (checkmark on the right) or delete this workout.", @"Отметьте подходы как выполненные (галочка справа) или удалите тренировку." },
    { @"Wróć", @"Back", @"Назад" },
    { @"Usuń trening", @"Delete workout", @"Удалить тренировку" },
    { @"Trening zapisany", @"Workout saved", @"Тренировка сохранена" },
    { @"Usunąć ten trening? Wpisane serie przepadną.", @"Delete this workout? Logged sets will be lost.", @"Удалить тренировку? Записанные подходы пропадут." },
    { @"Anuluj", @"Cancel", @"Отмена" },
    { @"Usuń", @"Delete", @"Удалить" },
    { @"Podgląd", @"Preview", @"Показать" },
    { @"+ Dodaj serię", @"+ Add set", @"+ Добавить подход" },
    { @"★ NOWY REKORD", @"★ NEW RECORD", @"★ НОВЫЙ РЕКОРД" },
    { @"Koniec przerwy. Czas na kolejną serię!", @"Rest is over. Time for the next set!", @"Отдых закончен. Пора на следующий подход!" },
    { @"powt.", @"reps", @"повт." },
    { @"Gotowe", @"Done", @"Готово" },
    { @"Brak danych", @"No data", @"Нет данных" },
    { @"Partia mięśni", @"Muscle group", @"Группа мышц" },
    { @"Szukaj ćwiczenia", @"Search exercises", @"Поиск упражнений" },
    { @"Nowe", @"New", @"Новое" },
    { @"Nowe ćwiczenie", @"New exercise", @"Новое упражнение" },
    { @"Podaj nazwę ćwiczenia", @"Enter the exercise name", @"Введите название упражнения" },
    { @"Dalej", @"Next", @"Далее" },
    { @"(usunięte ćwiczenie)", @"(deleted exercise)", @"(удалённое упражнение)" },
    { @"Klatka piersiowa", @"Chest", @"Грудь" },
    { @"Plecy", @"Back", @"Спина" },
    { @"Barki", @"Shoulders", @"Плечи" },
    { @"Biceps", @"Biceps", @"Бицепс" },
    { @"Triceps", @"Triceps", @"Трицепс" },
    { @"Przedramiona", @"Forearms", @"Предплечья" },
    { @"Brzuch", @"Abs", @"Пресс" },
    { @"Uda (przód)", @"Quads", @"Квадрицепс" },
    { @"Uda (tył)", @"Hamstrings", @"Бицепс бедра" },
    { @"Pośladki", @"Glutes", @"Ягодицы" },
    { @"Łydki", @"Calves", @"Икры" },
    { @"Cardio", @"Cardio", @"Кардио" },
    { @"Inne", @"Other", @"Другое" },
    { @"sztanga", @"barbell", @"штанга" },
    { @"hantle", @"dumbbells", @"гантели" },
    { @"maszyna", @"machine", @"тренажёр" },
    { @"wyciąg", @"cable", @"блок" },
    { @"masa ciała", @"bodyweight", @"свой вес" },
    { @"kettlebell", @"kettlebell", @"гиря" },
    { @"inne", @"other", @"другое" },
    { @"własne", @"custom", @"своё" },
    { @"Tu pojawią się twoje zakończone treningi.", @"Your finished workouts will show up here.", @"Здесь появятся ваши завершённые тренировки." },
    { @"Ten tydzień", @"This week", @"Эта неделя" },
    { @"min", @"min", @"мин" },
    { @"godz.", @"h", @"ч" },
    { @"Powtórz ten trening", @"Repeat this workout", @"Повторить эту тренировку" },
    { @"Trwa już trening", @"A workout is already in progress", @"Тренировка уже идёт" },
    { @"Zakończ albo usuń trwający trening, zanim zaczniesz nowy.", @"Finish or delete the current workout before starting a new one.", @"Завершите или удалите текущую тренировку, прежде чем начать новую." },
    { @"Wykres: szacowane 1RM", @"Chart: estimated 1RM", @"График: расчётный 1ПМ" },
    { @"Jeszcze nie robiłeś tego ćwiczenia.", @"You haven't done this exercise yet.", @"Вы ещё не делали это упражнение." },
    { @"Największy ciężar:  %@", @"Heaviest weight:  %@", @"Максимальный вес:  %@" },
    { @"Szacowane 1RM:  %@", @"Estimated 1RM:  %@", @"Расчётный 1ПМ:  %@" },
    { @"Łączna objętość:  %@", @"Total volume:  %@", @"Общий объём:  %@" },
    { @"Treningów:  %lu", @"Workouts:  %lu", @"Тренировок:  %lu" },
    { @"Dane", @"Data", @"Данные" },
    { @"O aplikacji", @"About", @"О приложении" },
    { @"Wygląd", @"Appearance", @"Оформление" },
    { @"Język", @"Language", @"Язык" },
    { @"Motyw", @"Theme", @"Тема" },
    { @"Automatycznie", @"Automatic", @"Автоматически" },
    { @"Jednostka ciężaru", @"Weight unit", @"Единица веса" },
    { @"funty (lb) — dotknij, aby zmienić", @"pounds (lb) — tap to change", @"фунты (lb) — нажмите, чтобы изменить" },
    { @"kilogramy (kg) — dotknij, aby zmienić", @"kilograms (kg) — tap to change", @"килограммы (кг) — нажмите, чтобы изменить" },
    { @"Przerwa między seriami", @"Rest between sets", @"Отдых между подходами" },
    { @"wyłączona — dotknij, aby zmienić", @"off — tap to change", @"выключен — нажмите, чтобы изменить" },
    { @"%ld s — dotknij, aby zmienić", @"%ld s — tap to change", @"%ld с — нажмите, чтобы изменить" },
    { @"Kopia zapasowa", @"Backup", @"Резервная копия" },
    { @"Plik silka.json jest w iTunes → Aplikacje → Udostępnianie plików", @"The silka.json file is in iTunes → Apps → File Sharing", @"Файл silka.json находится в iTunes → Программы → Общие файлы" },
    { @"Usuń wszystkie dane", @"Delete all data", @"Удалить все данные" },
    { @"Treningi, własne ćwiczenia i ustawienia", @"Workouts, custom exercises and settings", @"Тренировки, свои упражнения и настройки" },
    { @"Wersja", @"Version", @"Версия" },
    { @"Autor", @"Author", @"Автор" },
    { @"Baza ćwiczeń", @"Exercise database", @"База упражнений" },
    { @"free-exercise-db (domena publiczna), własne tłumaczenia", @"free-exercise-db (public domain), own translations", @"free-exercise-db (общественное достояние), собственные переводы" },
    { @"Zapisane tylko w twoim telefonie", @"Stored only on your phone", @"Хранятся только на вашем телефоне" },
    { @"Usunąć wszystkie treningi i dane? Tego nie da się cofnąć.", @"Delete all workouts and data? This cannot be undone.", @"Удалить все тренировки и данные? Это нельзя отменить." },
    { @"Usuń wszystko", @"Delete everything", @"Удалить всё" },
    { @"Grafit", @"Graphite", @"Графит" },
    { @"Błękit", @"Blue", @"Синий" },
    { @"Czerwień", @"Red", @"Красный" },
    { @"Zieleń", @"Green", @"Зелёный" },
    { @"Fiolet", @"Purple", @"Фиолетовый" },
    { @"Srebro", @"Silver", @"Серебро" },
    { @"Len", @"Linen", @"Лён" },
    { @"Zapraszamy!", @"Welcome!", @"Добро пожаловать!" },
    { @"Kolejny trening?", @"Another workout?", @"Ещё одна тренировка?" },
    { @"Do dzieła!", @"Let's get to work!", @"За дело!" },
    { @"Czas na serię!", @"Time for a set!", @"Пора на подход!" },
    { @"Dziś bijemy rekord?", @"Going for a record today?", @"Сегодня бьём рекорд?" },
    { @"Każdy trening się liczy.", @"Every workout counts.", @"Каждая тренировка важна." },
    { @"Mały krok, wielka forma.", @"Small steps, big shape.", @"Маленький шаг к большой форме." },
    { @"Żelazo już czeka.", @"The iron is waiting.", @"Железо уже ждёт." },
    { @"Rozgrzewka zrobiona?", @"Warmed up yet?", @"Размялся?" },
    { @"Dziś dobry dzień na trening.", @"Good day for a workout.", @"Хороший день для тренировки." },
    { @"Ostatnie powtórzenie robi różnicę.", @"The last rep makes the difference.", @"Последнее повторение решает." },
    { @"Ciężar sam się nie podniesie.", @"The weight won't lift itself.", @"Вес сам не поднимется." },
    { @"Jak się czujesz? Dasz radę!", @"Feeling strong? You've got this!", @"Как настроение? Ты справишься!" },
    { @"Wracamy do formy!", @"Back to form!", @"Возвращаемся в форму!" },
    { @"Game Center (beta)", @"Game Center (beta)", @"Game Center (бета)" },
    { @"Zdjęcia ćwiczeń", @"Exercise photos", @"Фото упражнений" },
    { @"Tekstura tła", @"Background texture", @"Текстура фона" },
    { @"systemowy, test OK", @"system, test OK", @"системный, тест OK" },
    { @"systemowy, test nieudany", @"system, test failed", @"системный, тест не пройден" },
    { @"Waga ciała", @"Body weight", @"Вес тела" },
    { @"Talia", @"Waist", @"Талия" },
    { @"Biodra", @"Hips", @"Бёдра" },
    { @"Udo", @"Thigh", @"Бедро" },
    { @"Pomiary ciała", @"Body measurements", @"Замеры тела" },
    { @"Brak pomiarów", @"No measurements", @"Нет замеров" },
    { @"+ Dodaj pomiar", @"+ Add measurement", @"+ Добавить замер" },
    { @"Podaj wagę (%@)", @"Enter weight (%@)", @"Введите вес (%@)" },
    { @"Podaj wartość (cm)", @"Enter value (cm)", @"Введите значение (см)" },
    { @"Zapisz", @"Save", @"Сохранить" },
    { @"Historia pomiarów", @"Measurement history", @"История замеров" },
    { @"Zdjęcia postępów", @"Progress photos", @"Фото прогресса" },
    { @"Dotknij +, żeby dodać pierwsze zdjęcie sylwetki.", @"Tap + to add your first body photo.", @"Нажмите +, чтобы добавить первое фото." },
    { @"Zrób zdjęcie", @"Take photo", @"Сделать фото" },
    { @"Wybierz z biblioteki", @"Choose from library", @"Выбрать из библиотеки" },
    { @"Nie udało się zapisać zdjęcia", @"Could not save the photo", @"Не удалось сохранить фото" },
    { @"Usunąć to zdjęcie?", @"Delete this photo?", @"Удалить это фото?" },
    { @"Plan zapisany", @"Plan saved", @"План сохранён" },
    { @"Znajdziesz go w zakładce Plany.", @"You'll find it in the Plans tab.", @"Он появится на вкладке «Планы»." },
    { @"Zapisz jako plan", @"Save as plan", @"Сохранить как план" },
    { @"Podaj nazwę planu", @"Enter a plan name", @"Введите название плана" },
    { @"Plany", @"Plans", @"Планы" },
    { @"Nowy plan", @"New plan", @"Новый план" },
    { @"Moje plany", @"My plans", @"Мои планы" },
    { @"Gotowe programy", @"Ready-made programs", @"Готовые программы" },
    { @"Brak planów", @"No plans", @"Нет планов" },
    { @"Dotknij +, zapisz trening z historii albo wybierz gotowy program.", @"Tap +, save a workout from history or pick a ready-made program.", @"Нажмите +, сохраните тренировку из истории или выберите готовую программу." },
    { @"Pusty plan: dodaj ćwiczenia", @"Empty plan: add exercises", @"Пустой план: добавьте упражнения" },
    { @"Zmień nazwę", @"Rename", @"Переименовать" },
    { @"Zapisz do moich planów", @"Save to my plans", @"Сохранить в мои планы" },
    { @"Pusty plan", @"Empty plan", @"Пустой план" },
    { @"Dodaj do planu przynajmniej jedno ćwiczenie.", @"Add at least one exercise to the plan.", @"Добавьте в план хотя бы одно упражнение." },
    { @"Dodaj wszystkie dni do planów", @"Add all days to my plans", @"Добавить все дни в планы" },
    { @"Dodano do planów", @"Added to plans", @"Добавлено в планы" },
    { @"Dni", @"Days", @"Дней" },
    { @"Pn", @"Mo", @"Пн" },
    { @"Wt", @"Tu", @"Вт" },
    { @"Śr", @"We", @"Ср" },
    { @"Cz", @"Th", @"Чт" },
    { @"Pt", @"Fr", @"Пт" },
    { @"Sb", @"Sa", @"Сб" },
    { @"Nd", @"Su", @"Вс" },
    { @"Postępy", @"Progress", @"Прогресс" },
    { @"Seria tyg.", @"Week streak", @"Серия нед." },
    { @"Rekordy", @"Records", @"Рекорды" },
    { @"Analiza treningów", @"Workout analysis", @"Анализ тренировок" },
    { @"Ciało", @"Body", @"Тело" },
    { @"Kalendarz", @"Calendar", @"Календарь" },
    { @"Dni, w które trenowałeś", @"Days you trained", @"Дни тренировок" },
    { @"z najlepszymi wynikami", @"with personal bests", @"с личными рекордами" },
    { @"Analiza i wykresy", @"Analysis and charts", @"Анализ и графики" },
    { @"Tygodnie, objętość, partie mięśni", @"Weeks, volume, muscle groups", @"Недели, объём, группы мышц" },
    { @"Waga", @"Weight", @"Вес" },
    { @"Waga, biceps, klatka, talia, biodra, udo", @"Weight, biceps, chest, waist, hips, thigh", @"Вес, бицепс, грудь, талия, бёдра, бедро" },
    { @"Porównuj sylwetkę w czasie", @"Compare your physique over time", @"Сравнивайте фигуру во времени" },
    { @"Treningi tego dnia", @"Workouts that day", @"Тренировки в этот день" },
    { @"Treningi w miesiącu", @"Workouts this month", @"Тренировки за месяц" },
    { @"Rekordy osobiste", @"Personal records", @"Личные рекорды" },
    { @"Brak rekordów", @"No records yet", @"Рекордов пока нет" },
    { @"Zakończ trening z wykonanymi seriami, a pojawią się tutaj.", @"Finish a workout with completed sets and they will show up here.", @"Завершите тренировку с выполненными подходами, и они появятся здесь." },
    { @"Treningi w tygodniu (8 tygodni)", @"Workouts per week (8 weeks)", @"Тренировки по неделям (8 недель)" },
    { @"Objętość w tygodniu", @"Weekly volume", @"Объём по неделям" },
    { @"7 dni", @"7 days", @"7 дней" },
    { @"30 dni", @"30 days", @"30 дней" },
    { @"90 dni", @"90 days", @"90 дней" },
    { @"Wszystko", @"All", @"Всё" },
    { @"Partie mięśni (serie)", @"Muscle groups (sets)", @"Группы мышц (подходы)" },
    { @"Brak wykonanych serii w tym okresie.", @"No completed sets in this period.", @"В этот период нет выполненных подходов." },
    { @"Nowe rekordy: %ld", @"New records: %ld", @"Новые рекорды: %ld" },
    { @"Całe ciało 3×", @"Full Body 3×", @"Всё тело 3×" },
    { @"Początkujący, 3 dni w tygodniu", @"Beginners, 3 days a week", @"Для начинающих, 3 дня в неделю" },
    { @"Push / Pull / Nogi", @"Push / Pull / Legs", @"Жим / Тяга / Ноги" },
    { @"Średniozaawansowani, 3–6 dni w tygodniu", @"Intermediate, 3–6 days a week", @"Средний уровень, 3–6 дней в неделю" },
    { @"Góra / Dół", @"Upper / Lower", @"Верх / Низ" },
    { @"4 dni w tygodniu (góra, dół, góra, dół)", @"4 days a week (upper, lower, upper, lower)", @"4 дня в неделю (верх, низ, верх, низ)" },
    { @"Maszyny dla początkujących", @"Machines for beginners", @"Тренажёры для начинающих" },
    { @"Prosty trening całego ciała na maszynach", @"Simple full-body workout on machines", @"Простая тренировка всего тела на тренажёрах" },
    { @"Ręce i brzuch", @"Arms and abs", @"Руки и пресс" },
    { @"Dodatkowy trening na ramiona i brzuch", @"Extra session for arms and abs", @"Дополнительная тренировка рук и пресса" },
    { @"Masa ciała", @"Bodyweight", @"Собственный вес" },
    { @"Bez sprzętu i na drążku", @"No equipment, just a bar", @"Без оборудования и на турнике" },
    { @"Całe ciało A", @"Full Body A", @"Всё тело A" },
    { @"Całe ciało B", @"Full Body B", @"Всё тело B" },
    { @"Całe ciało C", @"Full Body C", @"Всё тело C" },
    { @"Push (klatka, barki, triceps)", @"Push (chest, shoulders, triceps)", @"Жим (грудь, плечи, трицепс)" },
    { @"Pull (plecy, biceps)", @"Pull (back, biceps)", @"Тяга (спина, бицепс)" },
    { @"Nogi", @"Legs", @"Ноги" },
    { @"Góra ciała", @"Upper body", @"Верх тела" },
    { @"Dół ciała", @"Lower body", @"Низ тела" },
    { @"Maszyny", @"Machines", @"Тренажёры" },
    { @"kg", @"kg", @"кг" },
    { @"lb", @"lb", @"фнт" },
};

NSString *GL(NSString *pl)
{
    NSInteger l = SLLanguage();
    if (l == 0 || !pl) return pl;
    static NSDictionary *tables[2];
    if (!tables[l - 1]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (size_t i = 0; i < sizeof(kStrings) / sizeof(kStrings[0]); i++) {
            [d setObject:(l == 1 ? kStrings[i].en : kStrings[i].ru) forKey:kStrings[i].pl];
        }
        tables[l - 1] = d;
    }
    NSString *t = [tables[l - 1] objectForKey:pl];
    return t ? t : pl;
}


static const char *kGreetings[] = {
    "Zapraszamy!", "Kolejny trening?", "Do dzieła!", "Czas na serię!", "Dziś bijemy rekord?", "Każdy trening się liczy.",
    "Mały krok, wielka forma.", "Żelazo już czeka.", "Rozgrzewka zrobiona?", "Dziś dobry dzień na trening.",
    "Ostatnie powtórzenie robi różnicę.", "Ciężar sam się nie podniesie.", "Jak się czujesz? Dasz radę!", "Wracamy do formy!"
};
static NSInteger gGreetingIdx = -1;

#define NGREETINGS ((NSInteger)(sizeof(kGreetings) / sizeof(kGreetings[0])))

NSString *SLGreeting(void)
{
    if (gGreetingIdx < 0) gGreetingIdx = (NSInteger)(arc4random() % (uint32_t)NGREETINGS);
    return GL([NSString stringWithUTF8String:kGreetings[gGreetingIdx]]);
}

NSString *SLNextGreeting(void)
{
    NSInteger old = gGreetingIdx;
    NSInteger n = (NSInteger)(arc4random() % (uint32_t)NGREETINGS);
    if (n == old) n = (n + 1) % NGREETINGS;      /* zawsze inne niż poprzednie */
    gGreetingIdx = n;
    return GL([NSString stringWithUTF8String:kGreetings[gGreetingIdx]]);
}

/* formy: {pojedyncza, "kilka", reszta} dla każdego języka */
static const struct { NSString *forms[3][3]; } kNouns[] = {
    /* seria */      { { { @"seria", @"serie", @"serii" },               { @"set", @"sets", @"sets" },               { @"подход", @"подхода", @"подходов" } } },
    /* ćwiczenie */  { { { @"ćwiczenie", @"ćwiczenia", @"ćwiczeń" },     { @"exercise", @"exercises", @"exercises" }, { @"упражнение", @"упражнения", @"упражнений" } } },
    /* powtórzenie */{ { { @"powtórzenie", @"powtórzenia", @"powtórzeń" }, { @"rep", @"reps", @"reps" },              { @"повторение", @"повторения", @"повторений" } } },
    /* trening */    { { { @"trening", @"treningi", @"treningów" },       { @"workout", @"workouts", @"workouts" },   { @"тренировка", @"тренировки", @"тренировок" } } },
};

NSString *SLNounString(long n, int noun)
{
    if (noun < 0 || noun > 3) return @"";
    NSInteger l = SLLanguage();
    return kNouns[noun].forms[l][sl_plural((int)l, n)];
}

NSString *SLCountString(long n, int noun)
{
    return [NSString stringWithFormat:@"%ld %@", n, SLNounString(n, noun)];
}
