# Dokumentacja skryptu umożliwiająca tworzenie kopii przyrostowej oraz wysyłanie kopii przyrostowej na zdalny serwer.

## Skrypt wykorzystuje prawie w pełni wbudowane komendy w system Linux. Jedyna zależność, która została doinstalowana jest to rsync. Umożliwia to w łatwy sposób przesyłanie plików na zdalny serwer.
## Weryfikacja zainstalowanego tara
```
tar --version
```
## Sprawdzenie zainstalowanego openssl'a
```
openssl version
```
## Instalacja rsync
```
apt update
apt install rsync
```
## Kolejna ważna kwestia jest wydanie polecenia, który skopiuje nasz klucz publiczny z naszego lokalnego środowiska na zdalny. Spowoduje to pominiecie funkcji wpisywania hasła podczas wykonywania skryptu. Istotne w późniejszej fazie wykonywania skryptu automatycznie.
```
ssh-copy-id -i ~/.ssh/id_rsa.pub nazwa_uzytkownika@adres_do_zdalnego_serwera
```
## Dodanie skryptu do crontaba 
```
sudo crontab -e
```
## Ustawienie żeby skrypt wykonywał się raz dziennie, w tym przypadku o 18:00
```
0 18 * * * /lokalizacja/do/skryptu
```
## Opis działania skryptu
Skrypt skupia się na tworzeniu przyrostowych kopii zapasowych dla określonych lokalizacji, które użytkownik definiuje w pliku konfiguracyjnym.

Pierwsze wywołanie skryptu wykonuje pełną kopię wszystkich elementów znajdujących się w zadanej lokalizacji.
Kolejne wywołania bazują na zmianach w plikach i folderach, co jest monitorowane za pomocą pliku SNAPSHOT_FILE. Plik ten przechowuje informacje o wprowadzonych zmianach.
Podczas tworzenia archiwum skrypt korzysta z wbudowanego narzędzia tar, które zbiera wszystkie dane w jednym miejscu. Proces archiwizacji obejmuje również szyfrowanie nowo utworzonego pliku, które jest realizowane za pomocą narzędzia OpenSSL. W tym przypadku zastosowano algorytm AES-256-CBC do szyfrowania danych. Hasło do szyfrowania i deszyfrowania jest zdefiniowane w strukturze skryptu.

Funkcja odpowiedzialna za przesyłanie danych na zdalny serwer wykorzystuje rsync, który przyjmuje następujące argumenty:

* lokalizacja lokalnego pliku (plik do przesłania),
* dane do logowania na zdalnym serwerze (nazwa użytkownika, adres IPv4),
* ścieżka, w której ma zostać zapisana kopia przyrostowa,

Dodatkowo w skrypcie zaimplementowano funkcje weryfikujące istnienie folderów oraz plików niezbędnych do prawidłowego działania.

* Funkcja check_dirs(): Sprawdza, czy foldery podane przez użytkownika istnieją. Jeśli któryś z nich nie istnieje, skrypt zostaje natychmiast przerwany, aby uniknąć dalszych błędów,
* Metoda check_backup_dir(): Weryfikuje istnienie katalogu docelowego, w którym mają być przechowywane kopie zapasowe. Jeśli folder ten nie istnieje, funkcja automatycznie go tworzy,
* Funkcja check_snapshot_file(): Sprawdza, czy plik snapshot (odpowiedzialny za śledzenie zmian w plikach) został utworzony. Jeśli plik nie istnieje, funkcja go tworzy. Plik ten jest kluczowy, ponieważ przechowuje informacje o bieżących zmianach w plikach, co jest niezbędne do poprawnego wykonywania kopii przyrostowych.
