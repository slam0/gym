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
