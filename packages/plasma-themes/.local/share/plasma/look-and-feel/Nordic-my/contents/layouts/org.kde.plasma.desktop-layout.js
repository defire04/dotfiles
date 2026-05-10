var plasma = getApiVersion(1);

var layout = {
    "desktops": [
        {
            "applets": [
                {
                    "config": {
                        "/": {
                            "popupHeight": "524",
                            "popupWidth": "560"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "showSecondHand": "true"
                        }
                    },
                    "geometry.height": 0,
                    "geometry.width": 0,
                    "geometry.x": 0,
                    "geometry.y": 0,
                    "plugin": "org.kde.plasma.analogclock",
                    "title": "Часы с циферблатом"
                }
            ],
            "config": {
                "/": {
                    "ItemGeometries-1920x1080": "Applet-166:1536,32,384,320,0;",
                    "ItemGeometries-2560x1440": "Applet-166:2112,32,384,320,0;",
                    "ItemGeometriesHorizontal": "Applet-166:2112,32,384,320,0;",
                    "formfactor": "0",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                },
                "/ConfigDialog": {
                    "DialogHeight": "928",
                    "DialogWidth": "1231"
                },
                "/General": {
                    "changedPositions": "{\"desktop:/intellij-idea-ultimate.desktop\":[\"2560x1440\",\"0\",\"0\"]}",
                    "lastResolution": "2560x1440",
                    "positions": "{\"2560x1440\":[\"2\",\"23\",\"desktop:/The Witcher 3 Wild Hunt.desktop\",\"1\",\"0\",\"desktop:/intellij-idea-ultimate.desktop\",\"0\",\"0\"]}",
                    "sortMode": "-1"
                },
                "/Wallpaper/org.kde.image/General": {
                    "Image": "file:///mnt/samsung_990pro/Data/Media/Photos/Wallpaper/1586853771_daniel-leone-v7datklzzaw-unsplash-modded.webp",
                    "SlidePaths": "/home/dima/.local/share/wallpapers/,/usr/share/wallpapers/"
                }
            },
            "wallpaperPlugin": "org.kde.image"
        },
        {
            "applets": [
                {
                    "config": {
                        "/": {
                            "CurrentPreset": "org.kde.plasma.systemmonitor"
                        },
                        "/Appearance": {
                            "chartFace": "org.kde.ksysguard.horizontalbars",
                            "showTitle": "false",
                            "title": "Общая загрузка ЦП"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/SensorColors": {
                            "cpu/all/name": "124,61,233",
                            "cpu/all/system": "170,0,0",
                            "cpu/all/usage": "170,0,0",
                            "cpu/cpu\\d+/usage": "233,61,134",
                            "disk/0af05931f05923eb/used": "233,61,128",
                            "disk/0af05931f05923eb/usedPercent": "61,95,233",
                            "disk/8de062b5-7647-4989-886c-36204659cd51/used": "61,125,233",
                            "disk/e0b8f122b8f0f83c/used": "233,61,65",
                            "disk/e0c478d3c478ad82/used": "116,61,233",
                            "gpu/gpu0/usage": "0,170,0"
                        },
                        "/SensorLabels": {
                            "cpu/all/averageTemperature": "CPU Temperature",
                            "cpu/all/system": "Ryzen 7 7700",
                            "cpu/all/usage": "Ryzen 7 7700",
                            "disk/0af05931f05923eb/used": " Kingston KC3000 1TB",
                            "disk/0af05931f05923eb/usedPercent": "SSD Kingston KC3000",
                            "disk/8de062b5-7647-4989-886c-36204659cd51/used": "Kingston NV2 1TB",
                            "disk/e0b8f122b8f0f83c/used": "Samsung 990 PRO 4TB",
                            "disk/e0c478d3c478ad82/used": "HDD Toshiba P300 1TB",
                            "gpu/gpu0/temperature": "GPU Temperature",
                            "gpu/gpu0/usage": "RTX 4070 Super",
                            "memory/physical/application": "Memory Usage",
                            "memory/physical/used": "Memory Usage",
                            "os/kernel/prettyName": " ",
                            "os/system/uptime": "Uptime"
                        },
                        "/Sensors": {
                            "highPrioritySensorIds": "[\"cpu/all/usage\",\"gpu/gpu0/usage\",\"disk/8de062b5-7647-4989-886c-36204659cd51/used\",\"disk/e0b8f122b8f0f83c/used\",\"disk/0af05931f05923eb/used\",\"disk/e0c478d3c478ad82/used\"]",
                            "lowPrioritySensorIds": "[\"cpu/all/averageTemperature\",\"gpu/gpu0/temperature\",\"os/system/uptime\",\"memory/physical/used\",\"os/kernel/prettyName\"]",
                            "totalSensors": "[\"cpu/all/usage\"]"
                        }
                    },
                    "geometry.height": 0,
                    "geometry.width": 0,
                    "geometry.x": 0,
                    "geometry.y": 0,
                    "plugin": "org.kde.plasma.systemmonitor.cpu",
                    "title": "Общая загрузка ЦП"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "181",
                            "popupWidth": "288"
                        },
                        "/Appearance": {
                            "enableDangerColor": "true",
                            "showStats": "false"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "1209",
                            "DialogWidth": "1135"
                        },
                        "/General": {
                            "sensors": "[{\"name\":\"Ryzen 7 7700\",\"sensorId\":\"cpu/cpu0/temperature\"},{\"name\":\"RTX 4070 Super\",\"sensorId\":\"gpu/gpu0/temperature\"},{\"name\":\"Kingston NV2 1TB\",\"sensorId\":\"lmsensors/nvme-pci-0500/temp1\"},{\"name\":\"Samsung 990 PRO 4TB\",\"sensorId\":\"lmsensors/nvme-pci-0c00/temp1\"},{\"name\":\" Kingston KC3000 1TB\",\"sensorId\":\"lmsensors/nvme-pci-0200/temp1\"}]"
                        }
                    },
                    "geometry.height": 0,
                    "geometry.width": 0,
                    "geometry.x": 0,
                    "geometry.y": 0,
                    "plugin": "org.kde.olib.thermalmonitor",
                    "title": "Thermal Monitor"
                }
            ],
            "config": {
                "/": {
                    "ItemGeometries-1920x1080": "Applet-165:1472,0,144,464,0;Applet-93:1616,0,304,464,0;",
                    "ItemGeometries-2021x1137": "Applet-165:1472,0,144,464,0;Applet-93:1616,0,304,464,0;",
                    "ItemGeometries-2133x1200": "Applet-165:1472,0,144,464,0;Applet-93:1616,0,304,464,0;",
                    "ItemGeometries-2259x1271": "Applet-165:1472,0,144,464,0;Applet-93:1616,0,304,464,0;",
                    "ItemGeometries-2560x1440": "Applet-165:2112,0,160,464,0;Applet-93:2272,0,288,464,0;",
                    "ItemGeometries-640x480": "Applet-165:496,0,144,432,0;Applet-93:208,0,288,464,0;",
                    "ItemGeometriesHorizontal": "Applet-165:2112,0,160,464,0;Applet-93:2272,0,288,464,0;",
                    "formfactor": "0",
                    "immutability": "1",
                    "lastScreen": "1",
                    "wallpaperplugin": "org.kde.image"
                },
                "/ConfigDialog": {
                    "DialogHeight": "630",
                    "DialogWidth": "810"
                },
                "/General": {
                    "changedPositions": "{\"desktop:/The Witcher 3 Wild Hunt.desktop\":[\"2560x1440\",\"3\",\"8\"],\"desktop:/intellij-idea-ultimate.desktop\":[\"2560x1440\",\"3\",\"7\"]}",
                    "lastResolution": "2560x1440",
                    "positions": "{\"1920x1080\":[\"1\",\"17\"],\"2560x1440\":[\"4\",\"23\",\"desktop:/The Witcher 3 Wild Hunt.desktop\",\"3\",\"8\",\"desktop:/intellij-idea-ultimate.desktop\",\"3\",\"7\"]}",
                    "sortMode": "-1"
                },
                "/Wallpaper/org.kde.image/General": {
                    "Image": "file:///mnt/samsung_990pro/Data/Media/Photos/Wallpaper/1586853771_daniel-leone-v7datklzzaw-unsplash-modded.webp",
                    "SlidePaths": "/home/dima/.local/share/wallpapers/,/usr/share/wallpapers/"
                }
            },
            "wallpaperPlugin": "org.kde.image"
        }
    ],
    "panels": [
        {
            "alignment": "center",
            "applets": [
                {
                    "config": {
                        "/": {
                            "popupHeight": "519",
                            "popupWidth": "675"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "appNameFormat": "0",
                            "favoritesDisplay": "1",
                            "favoritesPortedToKAstats": "true",
                            "paneSwap": "true",
                            "systemFavorites": "suspend\\,hibernate\\,reboot\\,shutdown"
                        }
                    },
                    "plugin": "org.kde.plasma.kickoff"
                },
                {
                    "config": {
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "currentDesktopSelected": "ShowDesktop",
                            "displayedText": "Number",
                            "showOnlyCurrentScreen": "true",
                            "showWindowOutlines": "false",
                            "wrapPage": "true"
                        }
                    },
                    "plugin": "org.kde.plasma.pager"
                },
                {
                    "config": {
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "1273"
                        },
                        "/General": {
                            "forceStripes": "true",
                            "groupingAppIdBlacklist": "claude-desktop-native.desktop",
                            "groupingLauncherUrlBlacklist": "applications:claude-desktop-native.desktop",
                            "launchers": "applications:brave-browser.desktop"
                        }
                    },
                    "plugin": "org.kde.plasma.icontasks"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.marginsseparator"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "145",
                            "popupWidth": "540"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "useCustomFontSize": "true",
                            "useCustomIconSize": "true"
                        }
                    },
                    "plugin": "com.github.itayavra.batterywatch"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.systemtray"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "483",
                            "popupWidth": "396"
                        }
                    },
                    "plugin": "org.kde.plasma.digitalclock"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.showdesktop"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                }
            },
            "height": 3.3333333333333335,
            "hiding": "dodgewindows",
            "location": "bottom",
            "maximumLength": 142.22222222222223,
            "minimumLength": 142.22222222222223,
            "offset": 0
        },
        {
            "alignment": "center",
            "applets": [
                {
                    "config": {
                        "/": {
                            "popupHeight": "509",
                            "popupWidth": "673"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "alphaSort": "true",
                            "appNameFormat": "0",
                            "favoritesDisplay": "1",
                            "favoritesPortedToKAstats": "true",
                            "paneSwap": "true",
                            "systemFavorites": "suspend\\,hibernate\\,reboot\\,shutdown"
                        }
                    },
                    "plugin": "org.kde.plasma.kickoff"
                },
                {
                    "config": {
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "currentDesktopSelected": "ShowDesktop",
                            "displayedText": "Number",
                            "showOnlyCurrentScreen": "true",
                            "showWindowOutlines": "false",
                            "wrapPage": "true"
                        }
                    },
                    "plugin": "org.kde.plasma.pager"
                },
                {
                    "config": {
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "1273"
                        },
                        "/General": {
                            "forceStripes": "true",
                            "groupingAppIdBlacklist": "claude-desktop-native.desktop",
                            "groupingLauncherUrlBlacklist": "applications:claude-desktop-native.desktop",
                            "launchers": "preferred://browser"
                        }
                    },
                    "plugin": "org.kde.plasma.icontasks"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.marginsseparator"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.systemtray"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "483",
                            "popupWidth": "592"
                        }
                    },
                    "plugin": "org.kde.plasma.digitalclock"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.showdesktop"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "1",
                    "wallpaperplugin": "org.kde.image"
                }
            },
            "height": 2.4444444444444446,
            "hiding": "dodgewindows",
            "location": "bottom",
            "maximumLength": 142.22222222222223,
            "minimumLength": 142.22222222222223,
            "offset": 0
        }
    ],
    "serializationFormatVersion": "1"
}
;

plasma.loadSerializedLayout(layout);
