
How to update

1. Get latest database:

        git clone https://github.com/pavkam/tzdb ./bin/tz-db
		cd ./bin/tz-db
		./update-compile.sh


2. Copy `TZDB.inc`, `Version.inc` and `TZDB.pas` from `./bin/tz-db/src/TZDBPK` to the `./libtz/lib/tz-db`

3. Extract latest borders from [timezones.shapefile.zip](https://github.com/evansiroky/timezone-boundary-builder/releases) to the `./bin/tz-border`

4. Run `shp2pas.cmd`

5. Copy `*.pas` files from `./bin/pas` to the `./libtz/lib/tz-border`

6. Open `./libtz/libtz.lpi` with Lazarus 

7. Fix project Version Info, fix `CVersionInfo` in `src/u_AppMain.pas` and compile `libtz.dll`