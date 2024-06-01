module neo430_addr_gen
  (input  clk_i,
   input  [15:0] reg_i,
   input  [15:0] mem_i,
   input  [15:0] imm_i,
   input  [1:0] irq_sel_i,
   input  [28:0] ctrl_i,
   output [15:0] mem_addr_o,
   output [15:0] dwb_o);
  wire [15:0] mem_addr_reg;
  wire [15:0] addr_add;
  wire [2:0] n1524_o;
  wire n1526_o;
  wire n1528_o;
  wire n1530_o;
  wire n1532_o;
  wire [3:0] n1533_o;
  reg [15:0] n1537_o;
  wire [15:0] n1538_o;
  wire n1542_o;
  wire n1543_o;
  wire n1544_o;
  wire [15:0] n1545_o;
  wire n1550_o;
  wire n1551_o;
  wire [2:0] n1553_o;
  localparam [15:0] n1554_o = 16'b1100000000000000;
  wire [12:0] n1555_o;
  wire [15:0] n1556_o;
  wire [15:0] n1557_o;
  wire [15:0] n1558_o;
  wire [15:0] n1560_o;
  reg [15:0] n1561_q;
  assign mem_addr_o = n1558_o;
  assign dwb_o = addr_add;
  /* core/neo430_addr_gen.vhd:63:10  */
  assign mem_addr_reg = n1561_q; // (signal)
  /* core/neo430_addr_gen.vhd:64:10  */
  assign addr_add = n1538_o; // (signal)
  /* core/neo430_addr_gen.vhd:73:16  */
  assign n1524_o = ctrl_i[22:20];
  /* core/neo430_addr_gen.vhd:74:7  */
  assign n1526_o = n1524_o == 3'b000;
  /* core/neo430_addr_gen.vhd:75:7  */
  assign n1528_o = n1524_o == 3'b001;
  /* core/neo430_addr_gen.vhd:76:7  */
  assign n1530_o = n1524_o == 3'b010;
  /* core/neo430_addr_gen.vhd:77:7  */
  assign n1532_o = n1524_o == 3'b011;
  assign n1533_o = {n1532_o, n1530_o, n1528_o, n1526_o};
  /* core/neo430_addr_gen.vhd:73:5  */
  always @*
    case (n1533_o)
      4'b1000: n1537_o = 16'b1111111111111110;
      4'b0100: n1537_o = 16'b0000000000000010;
      4'b0010: n1537_o = 16'b0000000000000001;
      4'b0001: n1537_o = imm_i;
      default: n1537_o = mem_i;
    endcase
  /* core/neo430_addr_gen.vhd:80:51  */
  assign n1538_o = reg_i + n1537_o;
  /* core/neo430_addr_gen.vhd:92:17  */
  assign n1542_o = ctrl_i[26];
  /* core/neo430_addr_gen.vhd:93:19  */
  assign n1543_o = ctrl_i[23];
  /* core/neo430_addr_gen.vhd:93:40  */
  assign n1544_o = ~n1543_o;
  /* core/neo430_addr_gen.vhd:93:9  */
  assign n1545_o = n1544_o ? reg_i : addr_add;
  /* core/neo430_addr_gen.vhd:107:15  */
  assign n1550_o = ctrl_i[24];
  /* core/neo430_addr_gen.vhd:108:17  */
  assign n1551_o = ctrl_i[25];
  /* core/neo430_addr_gen.vhd:110:45  */
  assign n1553_o = {irq_sel_i, 1'b0};
  assign n1555_o = n1554_o[15:3];
  /* core/neo430_alu.vhd:102:22  */
  assign n1556_o = {n1555_o, n1553_o};
  /* core/neo430_addr_gen.vhd:108:7  */
  assign n1557_o = n1551_o ? n1556_o : reg_i;
  /* core/neo430_addr_gen.vhd:107:5  */
  assign n1558_o = n1550_o ? n1557_o : mem_addr_reg;
  /* core/neo430_addr_gen.vhd:91:5  */
  assign n1560_o = n1542_o ? n1545_o : mem_addr_reg;
  /* core/neo430_addr_gen.vhd:91:5  */
  always @(posedge clk_i)
    n1561_q <= n1560_o;
endmodule

module neo430_alu
  (input  clk_i,
   input  [15:0] reg_i,
   input  [15:0] mem_i,
   input  [15:0] sreg_i,
   input  [28:0] ctrl_i,
   output [15:0] data_o,
   output [4:0] flag_o);
  wire [15:0] op_data;
  wire [15:0] op_a_ff;
  wire [15:0] op_b_ff;
  wire [17:0] add_res;
  wire [15:0] alu_res;
  wire [15:0] data_res;
  wire zero;
  wire negative;
  wire parity;
  wire n1084_o;
  wire n1085_o;
  wire [15:0] n1086_o;
  wire n1089_o;
  wire n1091_o;
  wire [3:0] n1109_o;
  wire n1111_o;
  wire [3:0] n1112_o;
  wire n1114_o;
  wire n1115_o;
  wire [15:0] n1116_o;
  wire [15:0] n1117_o;
  wire n1120_o;
  wire [3:0] n1121_o;
  wire n1123_o;
  wire [3:0] n1124_o;
  wire n1126_o;
  wire n1127_o;
  wire n1128_o;
  wire n1129_o;
  wire [7:0] n1130_o;
  wire [8:0] n1132_o;
  wire [7:0] n1133_o;
  wire [8:0] n1135_o;
  wire [7:0] n1136_o;
  wire [8:0] n1138_o;
  wire [7:0] n1139_o;
  wire [8:0] n1141_o;
  wire [8:0] n1142_o;
  wire [8:0] n1143_o;
  wire [8:0] n1144_o;
  wire [8:0] n1145_o;
  wire n1146_o;
  wire [8:0] n1147_o;
  wire [8:0] n1148_o;
  wire n1149_o;
  wire n1150_o;
  wire n1151_o;
  wire n1152_o;
  wire n1153_o;
  wire n1154_o;
  wire n1155_o;
  wire n1156_o;
  wire n1157_o;
  wire n1158_o;
  wire n1159_o;
  wire n1160_o;
  wire n1161_o;
  wire n1162_o;
  wire n1163_o;
  wire n1164_o;
  wire n1165_o;
  wire n1166_o;
  wire n1167_o;
  wire n1168_o;
  wire n1169_o;
  wire n1170_o;
  wire n1171_o;
  wire n1172_o;
  wire n1173_o;
  wire n1174_o;
  wire n1175_o;
  wire n1176_o;
  wire [7:0] n1177_o;
  wire [7:0] n1178_o;
  wire [15:0] n1179_o;
  wire n1180_o;
  wire n1181_o;
  wire n1182_o;
  wire [1:0] n1183_o;
  wire [1:0] n1184_o;
  wire [1:0] n1185_o;
  wire [3:0] n1190_o;
  wire [15:0] n1191_o;
  wire n1192_o;
  wire n1193_o;
  wire n1195_o;
  wire n1197_o;
  wire n1198_o;
  wire n1200_o;
  wire n1201_o;
  wire n1203_o;
  wire n1204_o;
  wire n1206_o;
  wire n1207_o;
  wire [15:0] n1208_o;
  wire n1209_o;
  wire n1212_o;
  wire [15:0] n1213_o;
  wire n1214_o;
  wire n1215_o;
  wire n1216_o;
  wire n1217_o;
  wire n1218_o;
  wire n1219_o;
  wire n1220_o;
  wire n1221_o;
  wire n1222_o;
  wire n1224_o;
  wire [15:0] n1225_o;
  wire [15:0] n1226_o;
  wire n1227_o;
  wire n1228_o;
  wire n1229_o;
  wire n1230_o;
  wire n1232_o;
  wire [15:0] n1233_o;
  wire n1234_o;
  wire n1235_o;
  wire n1236_o;
  wire n1237_o;
  wire n1239_o;
  wire [15:0] n1240_o;
  wire n1241_o;
  wire n1244_o;
  wire n1245_o;
  wire n1246_o;
  wire [14:0] n1247_o;
  wire [15:0] n1248_o;
  wire n1249_o;
  wire n1250_o;
  wire n1251_o;
  wire n1252_o;
  wire [7:0] n1253_o;
  wire [6:0] n1254_o;
  wire n1255_o;
  wire [14:0] n1256_o;
  wire [15:0] n1257_o;
  wire n1258_o;
  wire n1259_o;
  wire n1260_o;
  wire n1261_o;
  wire [7:0] n1262_o;
  wire [6:0] n1263_o;
  wire [15:0] n1264_o;
  wire [15:0] n1265_o;
  wire [15:0] n1266_o;
  wire n1267_o;
  wire n1270_o;
  wire n1272_o;
  wire n1273_o;
  wire n1274_o;
  wire n1275_o;
  wire n1276_o;
  wire n1277_o;
  wire n1278_o;
  wire n1279_o;
  wire n1280_o;
  wire n1281_o;
  wire [7:0] n1282_o;
  wire n1283_o;
  wire n1286_o;
  wire [7:0] n1287_o;
  wire [7:0] n1288_o;
  wire [15:0] n1289_o;
  wire n1290_o;
  wire n1291_o;
  wire n1292_o;
  wire n1293_o;
  wire n1295_o;
  wire n1296_o;
  wire n1297_o;
  wire n1298_o;
  wire n1299_o;
  wire n1301_o;
  wire [9:0] n1307_o;
  reg n1308_o;
  reg n1309_o;
  reg n1310_o;
  reg n1311_o;
  reg n1312_o;
  wire [7:0] n1313_o;
  wire [7:0] n1314_o;
  wire [7:0] n1315_o;
  wire [7:0] n1316_o;
  wire [7:0] n1317_o;
  wire [7:0] n1318_o;
  wire [7:0] n1319_o;
  wire [7:0] n1320_o;
  wire [7:0] n1321_o;
  reg [7:0] n1323_o;
  wire n1324_o;
  wire n1325_o;
  wire n1326_o;
  wire n1327_o;
  wire n1328_o;
  wire n1329_o;
  wire n1330_o;
  wire n1331_o;
  wire n1332_o;
  reg n1334_o;
  wire n1335_o;
  wire n1336_o;
  wire n1337_o;
  wire n1338_o;
  wire n1339_o;
  wire n1340_o;
  wire n1341_o;
  wire n1342_o;
  wire n1343_o;
  reg n1345_o;
  wire n1346_o;
  wire n1347_o;
  wire n1348_o;
  wire n1349_o;
  wire n1350_o;
  wire n1351_o;
  wire n1352_o;
  wire n1353_o;
  wire n1354_o;
  reg n1356_o;
  wire n1357_o;
  wire n1358_o;
  wire n1359_o;
  wire n1360_o;
  wire n1361_o;
  wire n1362_o;
  wire n1363_o;
  wire n1364_o;
  wire n1365_o;
  reg n1367_o;
  wire n1368_o;
  wire n1369_o;
  wire n1370_o;
  wire n1371_o;
  wire n1372_o;
  wire n1373_o;
  wire n1374_o;
  wire n1375_o;
  wire n1376_o;
  reg n1378_o;
  wire n1379_o;
  wire n1380_o;
  wire n1381_o;
  wire n1382_o;
  wire n1383_o;
  wire n1384_o;
  wire n1385_o;
  wire n1386_o;
  wire n1387_o;
  reg n1389_o;
  wire n1390_o;
  wire n1391_o;
  wire n1392_o;
  wire n1393_o;
  wire n1394_o;
  wire n1395_o;
  wire n1396_o;
  wire n1397_o;
  wire n1398_o;
  reg n1400_o;
  wire n1401_o;
  wire n1402_o;
  wire n1403_o;
  wire n1404_o;
  wire n1405_o;
  wire n1406_o;
  wire n1407_o;
  wire n1408_o;
  wire n1409_o;
  reg n1411_o;
  wire [7:0] n1421_o;
  wire [7:0] n1422_o;
  wire n1423_o;
  wire n1424_o;
  wire [7:0] n1425_o;
  wire n1433_o;
  wire n1435_o;
  wire n1436_o;
  wire n1437_o;
  wire n1438_o;
  wire n1439_o;
  wire n1440_o;
  wire n1441_o;
  wire n1442_o;
  wire n1443_o;
  wire n1444_o;
  wire n1445_o;
  wire n1446_o;
  wire n1447_o;
  wire n1448_o;
  wire n1449_o;
  wire n1450_o;
  wire n1451_o;
  wire n1452_o;
  wire n1453_o;
  wire n1454_o;
  wire n1455_o;
  wire n1456_o;
  wire n1457_o;
  wire n1458_o;
  wire n1459_o;
  wire n1460_o;
  wire n1461_o;
  wire n1462_o;
  wire n1463_o;
  wire n1464_o;
  wire n1465_o;
  wire n1472_o;
  wire n1474_o;
  wire n1475_o;
  wire n1476_o;
  wire n1477_o;
  wire n1478_o;
  wire n1479_o;
  wire n1480_o;
  wire n1481_o;
  wire n1482_o;
  wire n1483_o;
  wire n1484_o;
  wire n1485_o;
  wire n1486_o;
  wire n1487_o;
  wire n1488_o;
  wire n1489_o;
  wire n1490_o;
  wire n1491_o;
  wire n1492_o;
  wire n1493_o;
  wire n1494_o;
  wire n1495_o;
  wire n1496_o;
  wire n1497_o;
  wire n1498_o;
  wire n1499_o;
  wire n1500_o;
  wire n1501_o;
  wire n1502_o;
  wire n1503_o;
  wire n1504_o;
  wire n1506_o;
  wire n1508_o;
  wire n1509_o;
  wire n1510_o;
  wire n1511_o;
  wire [15:0] n1512_o;
  reg [15:0] n1513_q;
  wire [15:0] n1514_o;
  reg [15:0] n1515_q;
  wire [17:0] n1516_o;
  wire [15:0] n1517_o;
  wire [15:0] n1518_o;
  wire [4:0] n1519_o;
  assign data_o = data_res;
  assign flag_o = n1519_o;
  /* core/neo430_alu.vhd:62:10  */
  assign op_data = n1086_o; // (signal)
  /* core/neo430_alu.vhd:63:10  */
  assign op_a_ff = n1513_q; // (signal)
  /* core/neo430_alu.vhd:64:10  */
  assign op_b_ff = n1515_q; // (signal)
  /* core/neo430_alu.vhd:65:10  */
  assign add_res = n1516_o; // (signal)
  /* core/neo430_alu.vhd:66:10  */
  assign alu_res = n1517_o; // (signal)
  /* core/neo430_alu.vhd:67:10  */
  assign data_res = n1518_o; // (signal)
  /* core/neo430_alu.vhd:68:10  */
  assign zero = n1465_o; // (signal)
  /* core/neo430_alu.vhd:69:10  */
  assign negative = n1510_o; // (signal)
  /* core/neo430_alu.vhd:70:10  */
  assign parity = n1506_o; // (signal)
  /* core/neo430_alu.vhd:76:32  */
  assign n1084_o = ctrl_i[12];
  /* core/neo430_alu.vhd:76:52  */
  assign n1085_o = ~n1084_o;
  /* core/neo430_alu.vhd:76:20  */
  assign n1086_o = n1085_o ? reg_i : mem_i;
  /* core/neo430_alu.vhd:85:17  */
  assign n1089_o = ctrl_i[13];
  /* core/neo430_alu.vhd:88:17  */
  assign n1091_o = ctrl_i[14];
  /* core/neo430_alu.vhd:108:15  */
  assign n1109_o = ctrl_i[18:15];
  /* core/neo430_alu.vhd:108:56  */
  assign n1111_o = n1109_o == 4'b0101;
  /* core/neo430_alu.vhd:109:15  */
  assign n1112_o = ctrl_i[18:15];
  /* core/neo430_alu.vhd:109:56  */
  assign n1114_o = n1112_o == 4'b0110;
  /* core/neo430_alu.vhd:108:69  */
  assign n1115_o = n1111_o | n1114_o;
  /* core/neo430_alu.vhd:113:23  */
  assign n1116_o = ~op_a_ff;
  /* core/neo430_alu.vhd:108:5  */
  assign n1117_o = n1115_o ? op_a_ff : n1116_o;
  /* core/neo430_alu.vhd:108:5  */
  assign n1120_o = n1115_o ? 1'b0 : 1'b1;
  /* core/neo430_alu.vhd:118:15  */
  assign n1121_o = ctrl_i[18:15];
  /* core/neo430_alu.vhd:118:56  */
  assign n1123_o = n1121_o == 4'b0110;
  /* core/neo430_alu.vhd:119:15  */
  assign n1124_o = ctrl_i[18:15];
  /* core/neo430_alu.vhd:119:56  */
  assign n1126_o = n1124_o == 4'b0111;
  /* core/neo430_alu.vhd:118:70  */
  assign n1127_o = n1123_o | n1126_o;
  /* core/neo430_alu.vhd:120:30  */
  assign n1128_o = sreg_i[0];
  /* core/neo430_alu.vhd:118:5  */
  assign n1129_o = n1127_o ? n1128_o : n1120_o;
  /* core/neo430_alu.vhd:126:27  */
  assign n1130_o = n1117_o[7:0];
  /* core/neo430_alu.vhd:126:19  */
  assign n1132_o = {1'b0, n1130_o};
  /* core/neo430_alu.vhd:127:27  */
  assign n1133_o = n1117_o[15:8];
  /* core/neo430_alu.vhd:127:19  */
  assign n1135_o = {1'b0, n1133_o};
  /* core/neo430_alu.vhd:128:28  */
  assign n1136_o = op_b_ff[7:0];
  /* core/neo430_alu.vhd:128:19  */
  assign n1138_o = {1'b0, n1136_o};
  /* core/neo430_alu.vhd:129:28  */
  assign n1139_o = op_b_ff[15:8];
  /* core/neo430_alu.vhd:129:19  */
  assign n1141_o = {1'b0, n1139_o};
  /* core/neo430_alu.vhd:132:52  */
  assign n1142_o = n1132_o + n1138_o;
  /* core/neo430_alu.vhd:132:71  */
  assign n1143_o = {8'b0, n1129_o};  //  uext
  /* core/neo430_alu.vhd:132:71  */
  assign n1144_o = n1142_o + n1143_o;
  /* core/neo430_alu.vhd:133:52  */
  assign n1145_o = n1135_o + n1141_o;
  /* core/neo430_alu.vhd:133:90  */
  assign n1146_o = n1144_o[8];
  /* core/neo430_alu.vhd:133:71  */
  assign n1147_o = {8'b0, n1146_o};  //  uext
  /* core/neo430_alu.vhd:133:71  */
  assign n1148_o = n1145_o + n1147_o;
  /* core/neo430_alu.vhd:136:29  */
  assign n1149_o = n1117_o[15];
  /* core/neo430_alu.vhd:136:19  */
  assign n1150_o = ~n1149_o;
  /* core/neo430_alu.vhd:136:51  */
  assign n1151_o = op_b_ff[15];
  /* core/neo430_alu.vhd:136:40  */
  assign n1152_o = ~n1151_o;
  /* core/neo430_alu.vhd:136:35  */
  assign n1153_o = n1150_o & n1152_o;
  /* core/neo430_alu.vhd:136:69  */
  assign n1154_o = n1148_o[7];
  /* core/neo430_alu.vhd:136:57  */
  assign n1155_o = n1153_o & n1154_o;
  /* core/neo430_alu.vhd:136:84  */
  assign n1156_o = n1117_o[15];
  /* core/neo430_alu.vhd:136:100  */
  assign n1157_o = op_b_ff[15];
  /* core/neo430_alu.vhd:136:89  */
  assign n1158_o = n1156_o & n1157_o;
  /* core/neo430_alu.vhd:136:122  */
  assign n1159_o = n1148_o[7];
  /* core/neo430_alu.vhd:136:110  */
  assign n1160_o = ~n1159_o;
  /* core/neo430_alu.vhd:136:105  */
  assign n1161_o = n1158_o & n1160_o;
  /* core/neo430_alu.vhd:136:74  */
  assign n1162_o = n1155_o | n1161_o;
  /* core/neo430_alu.vhd:137:29  */
  assign n1163_o = n1117_o[7];
  /* core/neo430_alu.vhd:137:19  */
  assign n1164_o = ~n1163_o;
  /* core/neo430_alu.vhd:137:51  */
  assign n1165_o = op_b_ff[7];
  /* core/neo430_alu.vhd:137:40  */
  assign n1166_o = ~n1165_o;
  /* core/neo430_alu.vhd:137:35  */
  assign n1167_o = n1164_o & n1166_o;
  /* core/neo430_alu.vhd:137:69  */
  assign n1168_o = n1144_o[7];
  /* core/neo430_alu.vhd:137:57  */
  assign n1169_o = n1167_o & n1168_o;
  /* core/neo430_alu.vhd:137:84  */
  assign n1170_o = n1117_o[7];
  /* core/neo430_alu.vhd:137:100  */
  assign n1171_o = op_b_ff[7];
  /* core/neo430_alu.vhd:137:89  */
  assign n1172_o = n1170_o & n1171_o;
  /* core/neo430_alu.vhd:137:122  */
  assign n1173_o = n1144_o[7];
  /* core/neo430_alu.vhd:137:110  */
  assign n1174_o = ~n1173_o;
  /* core/neo430_alu.vhd:137:105  */
  assign n1175_o = n1172_o & n1174_o;
  /* core/neo430_alu.vhd:137:74  */
  assign n1176_o = n1169_o | n1175_o;
  /* core/neo430_alu.vhd:140:37  */
  assign n1177_o = n1148_o[7:0];
  /* core/neo430_alu.vhd:140:60  */
  assign n1178_o = n1144_o[7:0];
  /* core/neo430_alu.vhd:140:50  */
  assign n1179_o = {n1177_o, n1178_o};
  /* core/neo430_alu.vhd:141:15  */
  assign n1180_o = ctrl_i[19];
  /* core/neo430_alu.vhd:142:30  */
  assign n1181_o = n1144_o[8];
  /* core/neo430_alu.vhd:145:30  */
  assign n1182_o = n1148_o[8];
  assign n1183_o = {n1162_o, n1182_o};
  assign n1184_o = {n1176_o, n1181_o};
  /* core/neo430_alu.vhd:141:5  */
  assign n1185_o = n1180_o ? n1184_o : n1183_o;
  /* core/neo430_alu.vhd:164:16  */
  assign n1190_o = ctrl_i[18:15];
  /* core/neo430_alu.vhd:171:27  */
  assign n1191_o = add_res[15:0];
  /* core/neo430_alu.vhd:172:36  */
  assign n1192_o = add_res[16];
  /* core/neo430_alu.vhd:173:36  */
  assign n1193_o = add_res[17];
  /* core/neo430_alu.vhd:165:7  */
  assign n1195_o = n1190_o == 4'b0101;
  /* core/neo430_alu.vhd:165:22  */
  assign n1197_o = n1190_o == 4'b0110;
  /* core/neo430_alu.vhd:165:22  */
  assign n1198_o = n1195_o | n1197_o;
  /* core/neo430_alu.vhd:165:35  */
  assign n1200_o = n1190_o == 4'b1000;
  /* core/neo430_alu.vhd:165:35  */
  assign n1201_o = n1198_o | n1200_o;
  /* core/neo430_alu.vhd:165:47  */
  assign n1203_o = n1190_o == 4'b0111;
  /* core/neo430_alu.vhd:165:47  */
  assign n1204_o = n1201_o | n1203_o;
  /* core/neo430_alu.vhd:165:60  */
  assign n1206_o = n1190_o == 4'b1001;
  /* core/neo430_alu.vhd:165:60  */
  assign n1207_o = n1204_o | n1206_o;
  /* core/neo430_alu.vhd:176:28  */
  assign n1208_o = op_a_ff & op_b_ff;
  /* core/neo430_alu.vhd:177:29  */
  assign n1209_o = ~zero;
  /* core/neo430_alu.vhd:175:7  */
  assign n1212_o = n1190_o == 4'b1111;
  /* core/neo430_alu.vhd:181:28  */
  assign n1213_o = op_a_ff ^ op_b_ff;
  /* core/neo430_alu.vhd:182:29  */
  assign n1214_o = ~zero;
  /* core/neo430_alu.vhd:183:36  */
  assign n1215_o = op_a_ff[15];
  /* core/neo430_alu.vhd:183:52  */
  assign n1216_o = op_b_ff[15];
  /* core/neo430_alu.vhd:183:41  */
  assign n1217_o = n1215_o & n1216_o;
  /* core/neo430_alu.vhd:184:19  */
  assign n1218_o = ctrl_i[19];
  /* core/neo430_alu.vhd:185:38  */
  assign n1219_o = op_a_ff[7];
  /* core/neo430_alu.vhd:185:53  */
  assign n1220_o = op_b_ff[7];
  /* core/neo430_alu.vhd:185:42  */
  assign n1221_o = n1219_o & n1220_o;
  /* core/neo430_alu.vhd:184:9  */
  assign n1222_o = n1218_o ? n1221_o : n1217_o;
  /* core/neo430_alu.vhd:180:7  */
  assign n1224_o = n1190_o == 4'b1110;
  /* core/neo430_alu.vhd:189:21  */
  assign n1225_o = ~op_a_ff;
  /* core/neo430_alu.vhd:189:34  */
  assign n1226_o = n1225_o & op_b_ff;
  /* core/neo430_alu.vhd:190:35  */
  assign n1227_o = sreg_i[0];
  /* core/neo430_alu.vhd:191:35  */
  assign n1228_o = sreg_i[8];
  /* core/neo430_alu.vhd:192:35  */
  assign n1229_o = sreg_i[2];
  /* core/neo430_alu.vhd:193:35  */
  assign n1230_o = sreg_i[1];
  /* core/neo430_alu.vhd:188:7  */
  assign n1232_o = n1190_o == 4'b1100;
  /* core/neo430_alu.vhd:196:28  */
  assign n1233_o = op_a_ff | op_b_ff;
  /* core/neo430_alu.vhd:197:35  */
  assign n1234_o = sreg_i[0];
  /* core/neo430_alu.vhd:198:35  */
  assign n1235_o = sreg_i[8];
  /* core/neo430_alu.vhd:199:35  */
  assign n1236_o = sreg_i[2];
  /* core/neo430_alu.vhd:200:35  */
  assign n1237_o = sreg_i[1];
  /* core/neo430_alu.vhd:195:7  */
  assign n1239_o = n1190_o == 4'b1101;
  /* core/neo430_alu.vhd:203:28  */
  assign n1240_o = op_a_ff & op_b_ff;
  /* core/neo430_alu.vhd:204:29  */
  assign n1241_o = ~zero;
  /* core/neo430_alu.vhd:202:7  */
  assign n1244_o = n1190_o == 4'b1011;
  /* core/neo430_alu.vhd:210:19  */
  assign n1245_o = ctrl_i[16];
  /* core/neo430_alu.vhd:211:29  */
  assign n1246_o = op_a_ff[15];
  /* core/neo430_alu.vhd:211:43  */
  assign n1247_o = op_a_ff[15:1];
  /* core/neo430_alu.vhd:211:34  */
  assign n1248_o = {n1246_o, n1247_o};
  /* core/neo430_alu.vhd:212:21  */
  assign n1249_o = ctrl_i[19];
  /* core/neo430_alu.vhd:213:34  */
  assign n1250_o = op_a_ff[7];
  assign n1251_o = n1248_o[7];
  /* core/neo430_alu.vhd:212:11  */
  assign n1252_o = n1249_o ? n1250_o : n1251_o;
  assign n1253_o = n1248_o[15:8];
  assign n1254_o = n1248_o[6:0];
  /* core/neo430_alu.vhd:216:28  */
  assign n1255_o = sreg_i[0];
  /* core/neo430_alu.vhd:216:48  */
  assign n1256_o = op_a_ff[15:1];
  /* core/neo430_alu.vhd:216:39  */
  assign n1257_o = {n1255_o, n1256_o};
  /* core/neo430_alu.vhd:217:21  */
  assign n1258_o = ctrl_i[19];
  /* core/neo430_alu.vhd:218:33  */
  assign n1259_o = sreg_i[0];
  assign n1260_o = n1257_o[7];
  /* core/neo430_alu.vhd:217:11  */
  assign n1261_o = n1258_o ? n1259_o : n1260_o;
  assign n1262_o = n1257_o[15:8];
  assign n1263_o = n1257_o[6:0];
  assign n1264_o = {n1262_o, n1261_o, n1263_o};
  assign n1265_o = {n1253_o, n1252_o, n1254_o};
  /* core/neo430_alu.vhd:210:9  */
  assign n1266_o = n1245_o ? n1265_o : n1264_o;
  /* core/neo430_alu.vhd:221:36  */
  assign n1267_o = op_a_ff[0];
  /* core/neo430_alu.vhd:207:7  */
  assign n1270_o = n1190_o == 4'b0010;
  /* core/neo430_alu.vhd:207:22  */
  assign n1272_o = n1190_o == 4'b0000;
  /* core/neo430_alu.vhd:207:22  */
  assign n1273_o = n1270_o | n1272_o;
  /* core/neo430_alu.vhd:226:32  */
  assign n1274_o = op_a_ff[7];
  /* core/neo430_alu.vhd:226:32  */
  assign n1275_o = op_a_ff[7];
  /* core/neo430_alu.vhd:226:32  */
  assign n1276_o = op_a_ff[7];
  /* core/neo430_alu.vhd:226:32  */
  assign n1277_o = op_a_ff[7];
  /* core/neo430_alu.vhd:226:32  */
  assign n1278_o = op_a_ff[7];
  /* core/neo430_alu.vhd:226:32  */
  assign n1279_o = op_a_ff[7];
  /* core/neo430_alu.vhd:226:32  */
  assign n1280_o = op_a_ff[7];
  /* core/neo430_alu.vhd:226:32  */
  assign n1281_o = op_a_ff[7];
  /* core/neo430_alu.vhd:228:39  */
  assign n1282_o = op_a_ff[7:0];
  /* core/neo430_alu.vhd:229:29  */
  assign n1283_o = ~zero;
  /* core/neo430_alu.vhd:224:7  */
  assign n1286_o = n1190_o == 4'b0011;
  /* core/neo430_alu.vhd:233:27  */
  assign n1287_o = op_a_ff[7:0];
  /* core/neo430_alu.vhd:233:49  */
  assign n1288_o = op_a_ff[15:8];
  /* core/neo430_alu.vhd:233:40  */
  assign n1289_o = {n1287_o, n1288_o};
  /* core/neo430_alu.vhd:234:35  */
  assign n1290_o = sreg_i[0];
  /* core/neo430_alu.vhd:235:35  */
  assign n1291_o = sreg_i[8];
  /* core/neo430_alu.vhd:236:35  */
  assign n1292_o = sreg_i[2];
  /* core/neo430_alu.vhd:237:35  */
  assign n1293_o = sreg_i[1];
  /* core/neo430_alu.vhd:232:7  */
  assign n1295_o = n1190_o == 4'b0001;
  /* core/neo430_alu.vhd:241:35  */
  assign n1296_o = sreg_i[0];
  /* core/neo430_alu.vhd:242:35  */
  assign n1297_o = sreg_i[8];
  /* core/neo430_alu.vhd:243:35  */
  assign n1298_o = sreg_i[2];
  /* core/neo430_alu.vhd:244:35  */
  assign n1299_o = sreg_i[1];
  /* core/neo430_alu.vhd:239:7  */
  assign n1301_o = n1190_o == 4'b0100;
  assign n1307_o = {n1301_o, n1295_o, n1286_o, n1273_o, n1244_o, n1239_o, n1232_o, n1224_o, n1212_o, n1207_o};
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1308_o = n1296_o;
      10'b0100000000: n1308_o = n1290_o;
      10'b0010000000: n1308_o = n1283_o;
      10'b0001000000: n1308_o = n1267_o;
      10'b0000100000: n1308_o = n1241_o;
      10'b0000010000: n1308_o = n1234_o;
      10'b0000001000: n1308_o = n1227_o;
      10'b0000000100: n1308_o = n1214_o;
      10'b0000000010: n1308_o = n1209_o;
      10'b0000000001: n1308_o = n1192_o;
      default: n1308_o = 1'bX;
    endcase
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1309_o = n1299_o;
      10'b0100000000: n1309_o = n1293_o;
      10'b0010000000: n1309_o = zero;
      10'b0001000000: n1309_o = zero;
      10'b0000100000: n1309_o = zero;
      10'b0000010000: n1309_o = n1237_o;
      10'b0000001000: n1309_o = n1230_o;
      10'b0000000100: n1309_o = zero;
      10'b0000000010: n1309_o = zero;
      10'b0000000001: n1309_o = zero;
      default: n1309_o = 1'bX;
    endcase
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1310_o = n1298_o;
      10'b0100000000: n1310_o = n1292_o;
      10'b0010000000: n1310_o = negative;
      10'b0001000000: n1310_o = negative;
      10'b0000100000: n1310_o = negative;
      10'b0000010000: n1310_o = n1236_o;
      10'b0000001000: n1310_o = n1229_o;
      10'b0000000100: n1310_o = negative;
      10'b0000000010: n1310_o = negative;
      10'b0000000001: n1310_o = negative;
      default: n1310_o = 1'bX;
    endcase
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1311_o = n1297_o;
      10'b0100000000: n1311_o = n1291_o;
      10'b0010000000: n1311_o = 1'b0;
      10'b0001000000: n1311_o = 1'b0;
      10'b0000100000: n1311_o = 1'b0;
      10'b0000010000: n1311_o = n1235_o;
      10'b0000001000: n1311_o = n1228_o;
      10'b0000000100: n1311_o = n1222_o;
      10'b0000000010: n1311_o = 1'b0;
      10'b0000000001: n1311_o = n1193_o;
      default: n1311_o = 1'bX;
    endcase
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1312_o = parity;
      10'b0100000000: n1312_o = parity;
      10'b0010000000: n1312_o = parity;
      10'b0001000000: n1312_o = parity;
      10'b0000100000: n1312_o = parity;
      10'b0000010000: n1312_o = parity;
      10'b0000001000: n1312_o = parity;
      10'b0000000100: n1312_o = parity;
      10'b0000000010: n1312_o = parity;
      10'b0000000001: n1312_o = parity;
      default: n1312_o = 1'bX;
    endcase
  assign n1313_o = n1191_o[7:0];
  assign n1314_o = n1208_o[7:0];
  assign n1315_o = n1213_o[7:0];
  assign n1316_o = n1226_o[7:0];
  assign n1317_o = n1233_o[7:0];
  assign n1318_o = n1240_o[7:0];
  assign n1319_o = n1266_o[7:0];
  assign n1320_o = n1289_o[7:0];
  assign n1321_o = op_a_ff[7:0];
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1323_o = n1321_o;
      10'b0100000000: n1323_o = n1320_o;
      10'b0010000000: n1323_o = n1282_o;
      10'b0001000000: n1323_o = n1319_o;
      10'b0000100000: n1323_o = n1318_o;
      10'b0000010000: n1323_o = n1317_o;
      10'b0000001000: n1323_o = n1316_o;
      10'b0000000100: n1323_o = n1315_o;
      10'b0000000010: n1323_o = n1314_o;
      10'b0000000001: n1323_o = n1313_o;
      default: n1323_o = 8'bX;
    endcase
  assign n1324_o = n1191_o[8];
  assign n1325_o = n1208_o[8];
  assign n1326_o = n1213_o[8];
  assign n1327_o = n1226_o[8];
  assign n1328_o = n1233_o[8];
  assign n1329_o = n1240_o[8];
  assign n1330_o = n1266_o[8];
  assign n1331_o = n1289_o[8];
  assign n1332_o = op_a_ff[8];
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1334_o = n1332_o;
      10'b0100000000: n1334_o = n1331_o;
      10'b0010000000: n1334_o = n1274_o;
      10'b0001000000: n1334_o = n1330_o;
      10'b0000100000: n1334_o = n1329_o;
      10'b0000010000: n1334_o = n1328_o;
      10'b0000001000: n1334_o = n1327_o;
      10'b0000000100: n1334_o = n1326_o;
      10'b0000000010: n1334_o = n1325_o;
      10'b0000000001: n1334_o = n1324_o;
      default: n1334_o = 1'bX;
    endcase
  assign n1335_o = n1191_o[9];
  assign n1336_o = n1208_o[9];
  assign n1337_o = n1213_o[9];
  assign n1338_o = n1226_o[9];
  assign n1339_o = n1233_o[9];
  assign n1340_o = n1240_o[9];
  assign n1341_o = n1266_o[9];
  assign n1342_o = n1289_o[9];
  assign n1343_o = op_a_ff[9];
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1345_o = n1343_o;
      10'b0100000000: n1345_o = n1342_o;
      10'b0010000000: n1345_o = n1275_o;
      10'b0001000000: n1345_o = n1341_o;
      10'b0000100000: n1345_o = n1340_o;
      10'b0000010000: n1345_o = n1339_o;
      10'b0000001000: n1345_o = n1338_o;
      10'b0000000100: n1345_o = n1337_o;
      10'b0000000010: n1345_o = n1336_o;
      10'b0000000001: n1345_o = n1335_o;
      default: n1345_o = 1'bX;
    endcase
  assign n1346_o = n1191_o[10];
  assign n1347_o = n1208_o[10];
  assign n1348_o = n1213_o[10];
  assign n1349_o = n1226_o[10];
  assign n1350_o = n1233_o[10];
  assign n1351_o = n1240_o[10];
  assign n1352_o = n1266_o[10];
  assign n1353_o = n1289_o[10];
  assign n1354_o = op_a_ff[10];
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1356_o = n1354_o;
      10'b0100000000: n1356_o = n1353_o;
      10'b0010000000: n1356_o = n1276_o;
      10'b0001000000: n1356_o = n1352_o;
      10'b0000100000: n1356_o = n1351_o;
      10'b0000010000: n1356_o = n1350_o;
      10'b0000001000: n1356_o = n1349_o;
      10'b0000000100: n1356_o = n1348_o;
      10'b0000000010: n1356_o = n1347_o;
      10'b0000000001: n1356_o = n1346_o;
      default: n1356_o = 1'bX;
    endcase
  assign n1357_o = n1191_o[11];
  assign n1358_o = n1208_o[11];
  assign n1359_o = n1213_o[11];
  assign n1360_o = n1226_o[11];
  assign n1361_o = n1233_o[11];
  assign n1362_o = n1240_o[11];
  assign n1363_o = n1266_o[11];
  assign n1364_o = n1289_o[11];
  assign n1365_o = op_a_ff[11];
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1367_o = n1365_o;
      10'b0100000000: n1367_o = n1364_o;
      10'b0010000000: n1367_o = n1277_o;
      10'b0001000000: n1367_o = n1363_o;
      10'b0000100000: n1367_o = n1362_o;
      10'b0000010000: n1367_o = n1361_o;
      10'b0000001000: n1367_o = n1360_o;
      10'b0000000100: n1367_o = n1359_o;
      10'b0000000010: n1367_o = n1358_o;
      10'b0000000001: n1367_o = n1357_o;
      default: n1367_o = 1'bX;
    endcase
  assign n1368_o = n1191_o[12];
  assign n1369_o = n1208_o[12];
  assign n1370_o = n1213_o[12];
  assign n1371_o = n1226_o[12];
  assign n1372_o = n1233_o[12];
  assign n1373_o = n1240_o[12];
  assign n1374_o = n1266_o[12];
  assign n1375_o = n1289_o[12];
  assign n1376_o = op_a_ff[12];
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1378_o = n1376_o;
      10'b0100000000: n1378_o = n1375_o;
      10'b0010000000: n1378_o = n1278_o;
      10'b0001000000: n1378_o = n1374_o;
      10'b0000100000: n1378_o = n1373_o;
      10'b0000010000: n1378_o = n1372_o;
      10'b0000001000: n1378_o = n1371_o;
      10'b0000000100: n1378_o = n1370_o;
      10'b0000000010: n1378_o = n1369_o;
      10'b0000000001: n1378_o = n1368_o;
      default: n1378_o = 1'bX;
    endcase
  assign n1379_o = n1191_o[13];
  assign n1380_o = n1208_o[13];
  assign n1381_o = n1213_o[13];
  assign n1382_o = n1226_o[13];
  assign n1383_o = n1233_o[13];
  assign n1384_o = n1240_o[13];
  assign n1385_o = n1266_o[13];
  assign n1386_o = n1289_o[13];
  assign n1387_o = op_a_ff[13];
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1389_o = n1387_o;
      10'b0100000000: n1389_o = n1386_o;
      10'b0010000000: n1389_o = n1279_o;
      10'b0001000000: n1389_o = n1385_o;
      10'b0000100000: n1389_o = n1384_o;
      10'b0000010000: n1389_o = n1383_o;
      10'b0000001000: n1389_o = n1382_o;
      10'b0000000100: n1389_o = n1381_o;
      10'b0000000010: n1389_o = n1380_o;
      10'b0000000001: n1389_o = n1379_o;
      default: n1389_o = 1'bX;
    endcase
  assign n1390_o = n1191_o[14];
  assign n1391_o = n1208_o[14];
  assign n1392_o = n1213_o[14];
  assign n1393_o = n1226_o[14];
  assign n1394_o = n1233_o[14];
  assign n1395_o = n1240_o[14];
  assign n1396_o = n1266_o[14];
  assign n1397_o = n1289_o[14];
  assign n1398_o = op_a_ff[14];
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1400_o = n1398_o;
      10'b0100000000: n1400_o = n1397_o;
      10'b0010000000: n1400_o = n1280_o;
      10'b0001000000: n1400_o = n1396_o;
      10'b0000100000: n1400_o = n1395_o;
      10'b0000010000: n1400_o = n1394_o;
      10'b0000001000: n1400_o = n1393_o;
      10'b0000000100: n1400_o = n1392_o;
      10'b0000000010: n1400_o = n1391_o;
      10'b0000000001: n1400_o = n1390_o;
      default: n1400_o = 1'bX;
    endcase
  assign n1401_o = n1191_o[15];
  assign n1402_o = n1208_o[15];
  assign n1403_o = n1213_o[15];
  assign n1404_o = n1226_o[15];
  assign n1405_o = n1233_o[15];
  assign n1406_o = n1240_o[15];
  assign n1407_o = n1266_o[15];
  assign n1408_o = n1289_o[15];
  assign n1409_o = op_a_ff[15];
  /* core/neo430_alu.vhd:164:5  */
  always @*
    case (n1307_o)
      10'b1000000000: n1411_o = n1409_o;
      10'b0100000000: n1411_o = n1408_o;
      10'b0010000000: n1411_o = n1281_o;
      10'b0001000000: n1411_o = n1407_o;
      10'b0000100000: n1411_o = n1406_o;
      10'b0000010000: n1411_o = n1405_o;
      10'b0000001000: n1411_o = n1404_o;
      10'b0000000100: n1411_o = n1403_o;
      10'b0000000010: n1411_o = n1402_o;
      10'b0000000001: n1411_o = n1401_o;
      default: n1411_o = 1'bX;
    endcase
  /* core/neo430_alu.vhd:262:35  */
  assign n1421_o = alu_res[7:0];
  /* core/neo430_alu.vhd:263:35  */
  assign n1422_o = alu_res[15:8];
  /* core/neo430_alu.vhd:263:61  */
  assign n1423_o = ctrl_i[19];
  /* core/neo430_alu.vhd:263:77  */
  assign n1424_o = ~n1423_o;
  /* core/neo430_alu.vhd:263:49  */
  assign n1425_o = n1424_o ? n1422_o : 8'b00000000;
  /* core/neo430_package.vhd:1004:15  */
  assign n1433_o = data_res[0];
  /* core/neo430_package.vhd:1006:26  */
  assign n1435_o = data_res[1];
  /* core/neo430_package.vhd:1006:22  */
  assign n1436_o = n1433_o | n1435_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1437_o = data_res[2];
  /* core/neo430_package.vhd:1006:22  */
  assign n1438_o = n1436_o | n1437_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1439_o = data_res[3];
  /* core/neo430_package.vhd:1006:22  */
  assign n1440_o = n1438_o | n1439_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1441_o = data_res[4];
  /* core/neo430_package.vhd:1006:22  */
  assign n1442_o = n1440_o | n1441_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1443_o = data_res[5];
  /* core/neo430_package.vhd:1006:22  */
  assign n1444_o = n1442_o | n1443_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1445_o = data_res[6];
  /* core/neo430_package.vhd:1006:22  */
  assign n1446_o = n1444_o | n1445_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1447_o = data_res[7];
  /* core/neo430_package.vhd:1006:22  */
  assign n1448_o = n1446_o | n1447_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1449_o = data_res[8];
  /* core/neo430_package.vhd:1006:22  */
  assign n1450_o = n1448_o | n1449_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1451_o = data_res[9];
  /* core/neo430_package.vhd:1006:22  */
  assign n1452_o = n1450_o | n1451_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1453_o = data_res[10];
  /* core/neo430_package.vhd:1006:22  */
  assign n1454_o = n1452_o | n1453_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1455_o = data_res[11];
  /* core/neo430_package.vhd:1006:22  */
  assign n1456_o = n1454_o | n1455_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1457_o = data_res[12];
  /* core/neo430_package.vhd:1006:22  */
  assign n1458_o = n1456_o | n1457_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1459_o = data_res[13];
  /* core/neo430_package.vhd:1006:22  */
  assign n1460_o = n1458_o | n1459_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1461_o = data_res[14];
  /* core/neo430_package.vhd:1006:22  */
  assign n1462_o = n1460_o | n1461_o;
  /* core/neo430_package.vhd:1006:26  */
  assign n1463_o = data_res[15];
  /* core/neo430_package.vhd:1006:22  */
  assign n1464_o = n1462_o | n1463_o;
  /* core/neo430_alu.vhd:266:11  */
  assign n1465_o = ~n1464_o;
  /* core/neo430_package.vhd:1028:15  */
  assign n1472_o = data_res[0];
  /* core/neo430_package.vhd:1030:27  */
  assign n1474_o = data_res[1];
  /* core/neo430_package.vhd:1030:22  */
  assign n1475_o = n1472_o ^ n1474_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1476_o = data_res[2];
  /* core/neo430_package.vhd:1030:22  */
  assign n1477_o = n1475_o ^ n1476_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1478_o = data_res[3];
  /* core/neo430_package.vhd:1030:22  */
  assign n1479_o = n1477_o ^ n1478_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1480_o = data_res[4];
  /* core/neo430_package.vhd:1030:22  */
  assign n1481_o = n1479_o ^ n1480_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1482_o = data_res[5];
  /* core/neo430_package.vhd:1030:22  */
  assign n1483_o = n1481_o ^ n1482_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1484_o = data_res[6];
  /* core/neo430_package.vhd:1030:22  */
  assign n1485_o = n1483_o ^ n1484_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1486_o = data_res[7];
  /* core/neo430_package.vhd:1030:22  */
  assign n1487_o = n1485_o ^ n1486_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1488_o = data_res[8];
  /* core/neo430_package.vhd:1030:22  */
  assign n1489_o = n1487_o ^ n1488_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1490_o = data_res[9];
  /* core/neo430_package.vhd:1030:22  */
  assign n1491_o = n1489_o ^ n1490_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1492_o = data_res[10];
  /* core/neo430_package.vhd:1030:22  */
  assign n1493_o = n1491_o ^ n1492_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1494_o = data_res[11];
  /* core/neo430_package.vhd:1030:22  */
  assign n1495_o = n1493_o ^ n1494_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1496_o = data_res[12];
  /* core/neo430_package.vhd:1030:22  */
  assign n1497_o = n1495_o ^ n1496_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1498_o = data_res[13];
  /* core/neo430_package.vhd:1030:22  */
  assign n1499_o = n1497_o ^ n1498_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1500_o = data_res[14];
  /* core/neo430_package.vhd:1030:22  */
  assign n1501_o = n1499_o ^ n1500_o;
  /* core/neo430_package.vhd:1030:27  */
  assign n1502_o = data_res[15];
  /* core/neo430_package.vhd:1030:22  */
  assign n1503_o = n1501_o ^ n1502_o;
  /* core/neo430_alu.vhd:269:14  */
  assign n1504_o = ~n1503_o;
  /* core/neo430_alu.vhd:269:39  */
  assign n1506_o = 1'b0 ? n1504_o : 1'bX;
  /* core/neo430_alu.vhd:272:23  */
  assign n1508_o = data_res[7];
  /* core/neo430_alu.vhd:272:39  */
  assign n1509_o = ctrl_i[19];
  /* core/neo430_alu.vhd:272:27  */
  assign n1510_o = n1509_o ? n1508_o : n1511_o;
  /* core/neo430_alu.vhd:272:75  */
  assign n1511_o = data_res[15];
  /* core/neo430_alu.vhd:83:5  */
  assign n1512_o = n1089_o ? op_data : op_a_ff;
  /* core/neo430_alu.vhd:83:5  */
  always @(posedge clk_i)
    n1513_q <= n1512_o;
  /* core/neo430_alu.vhd:83:5  */
  assign n1514_o = n1091_o ? op_data : op_b_ff;
  /* core/neo430_alu.vhd:83:5  */
  always @(posedge clk_i)
    n1515_q <= n1514_o;
  /* core/neo430_alu.vhd:83:5  */
  assign n1516_o = {n1185_o, n1179_o};
  assign n1517_o = {n1411_o, n1400_o, n1389_o, n1378_o, n1367_o, n1356_o, n1345_o, n1334_o, n1323_o};
  assign n1518_o = {n1425_o, n1421_o};
  assign n1519_o = {n1312_o, n1311_o, n1310_o, n1309_o, n1308_o};
endmodule

module neo430_reg_file_3f29546453678b855931c174a97d6c0894b8f546
  (input  clk_i,
   input  rst_i,
   input  [15:0] alu_i,
   input  [15:0] addr_i,
   input  [4:0] flag_i,
   input  [28:0] ctrl_i,
   output [15:0] data_o,
   output [15:0] sreg_o);
  wire [15:0] sreg;
  wire [15:0] sreg_int;
  wire [15:0] in_data;
  wire n914_o;
  wire [15:0] n915_o;
  wire n916_o;
  wire [15:0] n917_o;
  wire n919_o;
  wire [3:0] n921_o;
  wire n923_o;
  wire n924_o;
  wire n925_o;
  wire n926_o;
  wire n927_o;
  wire n928_o;
  wire n929_o;
  wire n930_o;
  wire n931_o;
  wire n932_o;
  wire n934_o;
  wire n936_o;
  wire n937_o;
  wire n938_o;
  wire n940_o;
  wire n941_o;
  wire n942_o;
  wire n943_o;
  wire n944_o;
  wire n945_o;
  wire n946_o;
  wire [2:0] n947_o;
  wire [2:0] n948_o;
  wire [2:0] n949_o;
  wire n950_o;
  wire n951_o;
  wire [4:0] n952_o;
  wire [4:0] n953_o;
  wire [4:0] n954_o;
  wire n955_o;
  wire n956_o;
  wire [2:0] n966_o;
  wire [2:0] n967_o;
  wire [4:0] n971_o;
  wire [4:0] n972_o;
  wire n976_o;
  wire n977_o;
  wire n980_o;
  localparam [15:0] n981_o = 16'b0000000000000000;
  wire n983_o;
  wire n985_o;
  wire n987_o;
  wire n989_o;
  wire n991_o;
  wire [2:0] n993_o;
  wire n994_o;
  wire [4:0] n996_o;
  wire n997_o;
  wire n998_o;
  localparam [15:0] n999_o = 16'b0000000000000000;
  wire n1001_o;
  wire n1003_o;
  wire n1005_o;
  wire n1007_o;
  wire n1009_o;
  wire [2:0] n1011_o;
  wire n1012_o;
  wire [5:0] n1013_o;
  wire n1017_o;
  wire [3:0] n1018_o;
  wire [3:0] n1027_o;
  wire n1029_o;
  wire [3:0] n1030_o;
  wire n1032_o;
  wire n1033_o;
  wire n1034_o;
  wire n1035_o;
  wire [1:0] n1036_o;
  wire n1037_o;
  wire [2:0] n1038_o;
  wire n1040_o;
  wire n1042_o;
  wire n1044_o;
  wire n1046_o;
  wire n1048_o;
  wire n1050_o;
  wire n1052_o;
  wire n1054_o;
  wire [7:0] n1055_o;
  reg [15:0] n1064_o;
  wire [3:0] n1065_o;
  wire [15:0] n1069_o;
  reg n1074_q;
  reg n1075_q;
  reg [4:0] n1076_q;
  wire [15:0] n1077_o;
  wire [15:0] n1078_o;
  wire [15:0] n1079_o;
  wire [15:0] n1080_data; // mem_rd
  assign data_o = n1069_o;
  assign sreg_o = n1079_o;
  /* core/neo430_reg_file.vhd:76:10  */
  assign sreg = n1077_o; // (signal)
  /* core/neo430_reg_file.vhd:77:10  */
  assign sreg_int = n1078_o; // (signal)
  /* core/neo430_reg_file.vhd:84:10  */
  assign in_data = n915_o; // (signal)
  /* core/neo430_reg_file.vhd:90:41  */
  assign n914_o = ctrl_i[11];
  /* core/neo430_reg_file.vhd:90:29  */
  assign n915_o = n914_o ? 16'b0000000000000000 : n917_o;
  /* core/neo430_reg_file.vhd:91:41  */
  assign n916_o = ctrl_i[0];
  /* core/neo430_reg_file.vhd:90:67  */
  assign n917_o = n916_o ? addr_i : alu_i;
  /* core/neo430_reg_file.vhd:98:15  */
  assign n919_o = ~rst_i;
  /* core/neo430_reg_file.vhd:102:18  */
  assign n921_o = ctrl_i[4:1];
  /* core/neo430_reg_file.vhd:102:57  */
  assign n923_o = n921_o == 4'b0010;
  /* core/neo430_reg_file.vhd:102:80  */
  assign n924_o = ctrl_i[8];
  /* core/neo430_reg_file.vhd:102:69  */
  assign n925_o = n924_o & n923_o;
  /* core/neo430_reg_file.vhd:103:34  */
  assign n926_o = in_data[0];
  /* core/neo430_reg_file.vhd:104:34  */
  assign n927_o = in_data[1];
  /* core/neo430_reg_file.vhd:105:34  */
  assign n928_o = in_data[2];
  /* core/neo430_reg_file.vhd:106:34  */
  assign n929_o = in_data[3];
  /* core/neo430_reg_file.vhd:107:34  */
  assign n930_o = in_data[4];
  /* core/neo430_reg_file.vhd:108:34  */
  assign n931_o = in_data[8];
  /* core/neo430_reg_file.vhd:109:34  */
  assign n932_o = in_data[14];
  /* core/neo430_reg_file.vhd:119:19  */
  assign n934_o = ctrl_i[9];
  assign n936_o = sreg[4];
  /* core/neo430_reg_file.vhd:119:9  */
  assign n937_o = n934_o ? 1'b0 : n936_o;
  /* core/neo430_reg_file.vhd:123:19  */
  assign n938_o = ctrl_i[10];
  assign n940_o = sreg[3];
  /* core/neo430_reg_file.vhd:123:9  */
  assign n941_o = n938_o ? 1'b0 : n940_o;
  /* core/neo430_reg_file.vhd:127:19  */
  assign n942_o = ctrl_i[7];
  /* core/neo430_reg_file.vhd:128:35  */
  assign n943_o = flag_i[0];
  /* core/neo430_reg_file.vhd:129:35  */
  assign n944_o = flag_i[1];
  /* core/neo430_reg_file.vhd:130:35  */
  assign n945_o = flag_i[2];
  /* core/neo430_reg_file.vhd:131:35  */
  assign n946_o = flag_i[3];
  assign n947_o = {n945_o, n944_o, n943_o};
  /* core/neo430_control.vhd:154:3  */
  assign n948_o = sreg[2:0];
  /* core/neo430_reg_file.vhd:127:9  */
  assign n949_o = n942_o ? n947_o : n948_o;
  assign n950_o = sreg[8];
  /* core/neo430_reg_file.vhd:127:9  */
  assign n951_o = n942_o ? n946_o : n950_o;
  assign n952_o = {n937_o, n941_o, n949_o};
  /* core/neo430_control.vhd:155:14  */
  assign n953_o = {n930_o, n929_o, n928_o, n927_o, n926_o};
  /* core/neo430_reg_file.vhd:102:7  */
  assign n954_o = n925_o ? n953_o : n952_o;
  /* core/neo430_reg_file.vhd:102:7  */
  assign n955_o = n925_o ? n931_o : n951_o;
  /* core/neo430_reg_file.vhd:102:7  */
  assign n956_o = n925_o ? n932_o : 1'b0;
  assign n966_o = sreg[7:5];
  /* core/neo430_reg_file.vhd:98:5  */
  assign n967_o = n919_o ? 3'b000 : n966_o;
  assign n971_o = sreg[13:9];
  /* core/neo430_reg_file.vhd:98:5  */
  assign n972_o = n919_o ? 5'b00000 : n971_o;
  assign n976_o = sreg[15];
  /* core/neo430_reg_file.vhd:98:5  */
  assign n977_o = n919_o ? 1'b0 : n976_o;
  /* core/neo430_reg_file.vhd:145:29  */
  assign n980_o = sreg[0];
  /* core/neo430_reg_file.vhd:146:29  */
  assign n983_o = sreg[1];
  /* core/neo430_reg_file.vhd:147:29  */
  assign n985_o = sreg[2];
  /* core/neo430_reg_file.vhd:148:29  */
  assign n987_o = sreg[3];
  /* core/neo430_reg_file.vhd:149:29  */
  assign n989_o = sreg[4];
  /* core/neo430_reg_file.vhd:150:29  */
  assign n991_o = sreg[8];
  assign n993_o = n981_o[7:5];
  /* core/neo430_reg_file.vhd:151:29  */
  assign n994_o = sreg[14];
  assign n996_o = n981_o[13:9];
  /* core/neo430_reg_file.vhd:152:29  */
  assign n997_o = sreg[15];
  /* core/neo430_reg_file.vhd:158:31  */
  assign n998_o = sreg[0];
  /* core/neo430_reg_file.vhd:159:31  */
  assign n1001_o = sreg[1];
  /* core/neo430_reg_file.vhd:160:31  */
  assign n1003_o = sreg[2];
  /* core/neo430_reg_file.vhd:161:31  */
  assign n1005_o = sreg[3];
  /* core/neo430_reg_file.vhd:162:31  */
  assign n1007_o = sreg[4];
  /* core/neo430_reg_file.vhd:163:31  */
  assign n1009_o = sreg[8];
  assign n1011_o = n999_o[7:5];
  /* core/neo430_reg_file.vhd:165:31  */
  assign n1012_o = sreg[15];
  assign n1013_o = n999_o[14:9];
  /* core/neo430_reg_file.vhd:175:17  */
  assign n1017_o = ctrl_i[8];
  /* core/neo430_reg_file.vhd:176:44  */
  assign n1018_o = ctrl_i[4:1];
  /* core/neo430_reg_file.vhd:187:16  */
  assign n1027_o = ctrl_i[4:1];
  /* core/neo430_reg_file.vhd:187:55  */
  assign n1029_o = n1027_o == 4'b0010;
  /* core/neo430_reg_file.vhd:188:16  */
  assign n1030_o = ctrl_i[4:1];
  /* core/neo430_reg_file.vhd:188:55  */
  assign n1032_o = n1030_o == 4'b0011;
  /* core/neo430_reg_file.vhd:187:67  */
  assign n1033_o = n1029_o | n1032_o;
  /* core/neo430_reg_file.vhd:190:28  */
  assign n1034_o = ctrl_i[1];
  /* core/neo430_reg_file.vhd:190:53  */
  assign n1035_o = ctrl_i[6];
  /* core/neo430_reg_file.vhd:190:45  */
  assign n1036_o = {n1034_o, n1035_o};
  /* core/neo430_reg_file.vhd:190:77  */
  assign n1037_o = ctrl_i[5];
  /* core/neo430_reg_file.vhd:190:69  */
  assign n1038_o = {n1036_o, n1037_o};
  /* core/neo430_reg_file.vhd:192:9  */
  assign n1040_o = n1038_o == 3'b000;
  /* core/neo430_reg_file.vhd:193:9  */
  assign n1042_o = n1038_o == 3'b001;
  /* core/neo430_reg_file.vhd:194:9  */
  assign n1044_o = n1038_o == 3'b010;
  /* core/neo430_reg_file.vhd:195:9  */
  assign n1046_o = n1038_o == 3'b011;
  /* core/neo430_reg_file.vhd:196:9  */
  assign n1048_o = n1038_o == 3'b100;
  /* core/neo430_reg_file.vhd:197:9  */
  assign n1050_o = n1038_o == 3'b101;
  /* core/neo430_reg_file.vhd:198:9  */
  assign n1052_o = n1038_o == 3'b110;
  /* core/neo430_reg_file.vhd:199:9  */
  assign n1054_o = n1038_o == 3'b111;
  assign n1055_o = {n1054_o, n1052_o, n1050_o, n1048_o, n1046_o, n1044_o, n1042_o, n1040_o};
  /* core/neo430_reg_file.vhd:191:7  */
  always @*
    case (n1055_o)
      8'b10000000: n1064_o = 16'b1111111111111111;
      8'b01000000: n1064_o = 16'b0000000000000010;
      8'b00100000: n1064_o = 16'b0000000000000001;
      8'b00010000: n1064_o = 16'b0000000000000000;
      8'b00001000: n1064_o = 16'b0000000000001000;
      8'b00000100: n1064_o = 16'b0000000000000100;
      8'b00000010: n1064_o = 16'b0000000000000000;
      8'b00000001: n1064_o = sreg_int;
      default: n1064_o = 16'bX;
    endcase
  /* core/neo430_reg_file.vhd:203:52  */
  assign n1065_o = ctrl_i[4:1];
  /* core/neo430_reg_file.vhd:187:5  */
  assign n1069_o = n1033_o ? n1064_o : n1080_data;
  /* core/neo430_reg_file.vhd:100:5  */
  always @(posedge clk_i or posedge n919_o)
    if (n919_o)
      n1074_q <= 1'b0;
    else
      n1074_q <= n956_o;
  /* core/neo430_reg_file.vhd:100:5  */
  always @(posedge clk_i or posedge n919_o)
    if (n919_o)
      n1075_q <= 1'b0;
    else
      n1075_q <= n955_o;
  /* core/neo430_reg_file.vhd:100:5  */
  always @(posedge clk_i or posedge n919_o)
    if (n919_o)
      n1076_q <= 5'b00000;
    else
      n1076_q <= n954_o;
  /* core/neo430_reg_file.vhd:98:5  */
  assign n1077_o = {n977_o, n1074_q, n972_o, n1075_q, n967_o, n1076_q};
  /* core/neo430_reg_file.vhd:98:5  */
  assign n1078_o = {n1012_o, n1013_o, n1009_o, n1011_o, n1007_o, n1005_o, n1003_o, n1001_o, n998_o};
  /* core/neo430_reg_file.vhd:98:5  */
  assign n1079_o = {n997_o, n994_o, n996_o, n991_o, n993_o, n989_o, n987_o, n985_o, n983_o, n980_o};
  /* core/neo430_reg_file.vhd:61:5  */
  reg [15:0] reg_file[15:0] ; // memory
  assign n1080_data = reg_file[n1065_o];
  always @(posedge clk_i)
    if (n1017_o)
      reg_file[n1018_o] <= in_data;
  /* core/neo430_reg_file.vhd:203:26  */
  /* core/neo430_reg_file.vhd:176:18  */
endmodule

module neo430_control
  (input  clk_i,
   input  rst_i,
   input  [15:0] instr_i,
   input  [15:0] sreg_i,
   input  [3:0] irq_i,
   output [28:0] ctrl_o,
   output [1:0] irq_vec_o,
   output [15:0] imm_o);
  wire [15:0] ir;
  wire ir_wren;
  wire branch_taken;
  wire [4:0] state;
  wire [4:0] state_nxt;
  wire [28:0] ctrl_nxt;
  wire [28:0] ctrl;
  wire [3:0] am_nxt;
  wire [3:0] am;
  wire mem_rd;
  wire mem_rd_ff;
  wire [3:0] src_nxt;
  wire [3:0] src;
  wire [1:0] sam_nxt;
  wire [1:0] sam;
  wire irq_fire;
  wire irq_start;
  wire irq_ack;
  wire [3:0] irq_ack_mask;
  wire [3:0] irq_buf;
  wire [1:0] irq_vec_nxt;
  wire [1:0] irq_vec;
  wire i_flag_ff0;
  wire i_flag_ff1;
  wire [2:0] n106_o;
  wire n107_o;
  wire n108_o;
  wire n110_o;
  wire n111_o;
  wire n113_o;
  wire n114_o;
  wire n115_o;
  wire n117_o;
  wire n118_o;
  wire n120_o;
  wire n121_o;
  wire n123_o;
  wire n124_o;
  wire n125_o;
  wire n126_o;
  wire n127_o;
  wire n129_o;
  wire n130_o;
  wire n131_o;
  wire n132_o;
  wire n134_o;
  wire n136_o;
  wire [7:0] n137_o;
  reg n140_o;
  wire n142_o;
  wire n143_o;
  wire [1:0] n144_o;
  wire n145_o;
  wire [2:0] n146_o;
  wire n147_o;
  wire [3:0] n148_o;
  wire n149_o;
  wire [4:0] n150_o;
  wire [9:0] n151_o;
  wire [14:0] n152_o;
  wire [15:0] n154_o;
  wire n156_o;
  wire [3:0] n173_o;
  wire n175_o;
  wire n178_o;
  wire n179_o;
  wire n183_o;
  localparam [28:0] n190_o = 29'b00000000000000000000000000000;
  wire n192_o;
  wire [3:0] n193_o;
  wire n201_o;
  wire [6:0] n202_o;
  wire n204_o;
  wire n207_o;
  wire [3:0] n209_o;
  wire n211_o;
  wire n214_o;
  wire [3:0] n216_o;
  wire n218_o;
  wire [3:0] n219_o;
  wire n221_o;
  wire n222_o;
  wire n225_o;
  wire n231_o;
  wire n236_o;
  wire n237_o;
  wire [4:0] n241_o;
  wire n242_o;
  wire n243_o;
  wire n244_o;
  wire [4:0] n246_o;
  wire n247_o;
  wire n248_o;
  wire n249_o;
  wire n251_o;
  wire n253_o;
  wire n254_o;
  wire [1:0] n255_o;
  wire [1:0] n258_o;
  wire n260_o;
  wire n261_o;
  wire [2:0] n262_o;
  wire n264_o;
  wire n265_o;
  wire n266_o;
  wire n267_o;
  wire [3:0] n269_o;
  wire n271_o;
  wire [3:0] n272_o;
  wire n274_o;
  wire n275_o;
  wire n276_o;
  wire n277_o;
  wire [1:0] n279_o;
  wire [1:0] n280_o;
  wire [3:0] n281_o;
  wire [6:0] n282_o;
  wire n284_o;
  wire [1:0] n285_o;
  wire [3:0] n287_o;
  wire [3:0] n289_o;
  wire [2:0] n290_o;
  wire n292_o;
  wire n294_o;
  wire n296_o;
  wire n298_o;
  wire [3:0] n299_o;
  reg [4:0] n305_o;
  wire [4:0] n307_o;
  wire [3:0] n308_o;
  wire [3:0] n309_o;
  wire [3:0] n310_o;
  wire [3:0] n311_o;
  wire [4:0] n313_o;
  wire n314_o;
  wire n315_o;
  wire [3:0] n316_o;
  wire [3:0] n317_o;
  wire [3:0] n318_o;
  wire [3:0] n320_o;
  wire n322_o;
  wire [3:0] n323_o;
  wire n325_o;
  wire n326_o;
  wire n327_o;
  wire n328_o;
  wire [1:0] n330_o;
  wire [1:0] n331_o;
  wire n332_o;
  wire [3:0] n333_o;
  wire [3:0] n334_o;
  wire [3:0] n335_o;
  wire n337_o;
  wire [4:0] n340_o;
  wire [4:0] n341_o;
  wire n343_o;
  wire [3:0] n344_o;
  wire [3:0] n345_o;
  wire [3:0] n346_o;
  wire [3:0] n347_o;
  wire n349_o;
  wire n352_o;
  wire n354_o;
  wire n355_o;
  wire [4:0] n358_o;
  wire [4:0] n360_o;
  wire n362_o;
  wire n364_o;
  wire n365_o;
  wire n367_o;
  wire n368_o;
  wire [1:0] n372_o;
  wire n374_o;
  wire [4:0] n377_o;
  wire n379_o;
  wire n381_o;
  wire n382_o;
  wire n384_o;
  wire n385_o;
  wire n387_o;
  wire n388_o;
  wire n394_o;
  wire n397_o;
  wire n399_o;
  wire n400_o;
  wire n402_o;
  wire n403_o;
  wire n405_o;
  wire n406_o;
  wire n408_o;
  wire n409_o;
  wire n411_o;
  wire n412_o;
  wire [2:0] n415_o;
  wire [3:0] n417_o;
  reg [4:0] n421_o;
  reg [3:0] n422_o;
  wire n423_o;
  reg n424_o;
  wire n425_o;
  reg n426_o;
  reg [2:0] n427_o;
  reg n428_o;
  reg n429_o;
  reg n432_o;
  wire n434_o;
  wire n439_o;
  wire n440_o;
  wire [4:0] n443_o;
  wire [4:0] n445_o;
  wire n447_o;
  wire n449_o;
  wire n450_o;
  wire n452_o;
  wire n453_o;
  wire n455_o;
  wire n456_o;
  wire n458_o;
  wire n459_o;
  wire n461_o;
  wire n462_o;
  wire n469_o;
  wire n471_o;
  wire n472_o;
  wire [1:0] n475_o;
  reg [4:0] n478_o;
  wire n479_o;
  reg n480_o;
  wire n481_o;
  reg n482_o;
  wire n483_o;
  reg n484_o;
  wire n485_o;
  reg n486_o;
  wire n487_o;
  reg n488_o;
  reg n489_o;
  reg n492_o;
  wire n494_o;
  wire n500_o;
  wire [3:0] n501_o;
  wire n505_o;
  wire [3:0] n507_o;
  wire n509_o;
  wire n512_o;
  wire n514_o;
  wire n516_o;
  wire n517_o;
  wire n519_o;
  wire n520_o;
  wire n522_o;
  wire n523_o;
  localparam [1:0] n524_o = 2'b00;
  wire [1:0] n526_o;
  wire n528_o;
  wire [4:0] n531_o;
  reg [4:0] n533_o;
  wire n534_o;
  reg n535_o;
  wire n536_o;
  reg n537_o;
  wire n538_o;
  reg n539_o;
  wire n540_o;
  reg n541_o;
  reg n543_o;
  wire n545_o;
  wire n548_o;
  wire n549_o;
  wire n550_o;
  wire n551_o;
  wire n552_o;
  wire [4:0] n555_o;
  wire [4:0] n557_o;
  wire n559_o;
  wire n561_o;
  wire n562_o;
  wire n564_o;
  wire n565_o;
  wire n567_o;
  wire n568_o;
  wire [4:0] n572_o;
  wire n574_o;
  wire [4:0] n577_o;
  wire [1:0] n578_o;
  reg [4:0] n579_o;
  wire n580_o;
  reg n581_o;
  wire n582_o;
  reg n583_o;
  wire n585_o;
  wire n589_o;
  wire [3:0] n590_o;
  wire n591_o;
  wire n592_o;
  wire n593_o;
  wire n594_o;
  wire n595_o;
  wire n596_o;
  wire n597_o;
  wire n599_o;
  wire n606_o;
  wire [4:0] n609_o;
  wire n611_o;
  wire n615_o;
  wire n618_o;
  wire n625_o;
  wire n634_o;
  wire n640_o;
  wire n643_o;
  wire n651_o;
  wire n654_o;
  wire n662_o;
  wire n669_o;
  wire n674_o;
  wire n677_o;
  wire [23:0] n678_o;
  reg n681_o;
  reg [4:0] n701_o;
  reg n702_o;
  reg [3:0] n703_o;
  wire n704_o;
  reg n705_o;
  wire n706_o;
  reg n707_o;
  wire n708_o;
  reg n709_o;
  wire n710_o;
  reg n711_o;
  wire n712_o;
  reg n713_o;
  wire n714_o;
  reg n715_o;
  wire n716_o;
  reg n717_o;
  wire n718_o;
  reg n719_o;
  wire n720_o;
  reg n721_o;
  wire n722_o;
  reg n723_o;
  reg [3:0] n724_o;
  reg n725_o;
  reg [2:0] n726_o;
  wire n727_o;
  reg n728_o;
  wire n729_o;
  reg n730_o;
  wire n731_o;
  reg n732_o;
  wire n733_o;
  reg n734_o;
  wire n735_o;
  reg n736_o;
  reg n737_o;
  reg [3:0] n750_o;
  reg n753_o;
  reg [3:0] n755_o;
  reg [1:0] n757_o;
  reg n760_o;
  wire n765_o;
  wire n766_o;
  wire n767_o;
  wire n768_o;
  wire n769_o;
  wire n770_o;
  wire n771_o;
  wire n772_o;
  wire n773_o;
  wire n774_o;
  wire n775_o;
  wire n776_o;
  wire n777_o;
  wire n778_o;
  wire n779_o;
  wire n780_o;
  wire n781_o;
  wire n782_o;
  wire n783_o;
  wire n784_o;
  wire n785_o;
  wire n786_o;
  wire n787_o;
  wire n788_o;
  wire n789_o;
  wire n790_o;
  wire n791_o;
  wire n792_o;
  wire n793_o;
  wire n794_o;
  wire n795_o;
  wire n796_o;
  wire n797_o;
  wire n798_o;
  wire n799_o;
  wire n800_o;
  wire n801_o;
  wire n802_o;
  wire n803_o;
  wire n804_o;
  wire n805_o;
  wire n808_o;
  wire n812_o;
  wire n813_o;
  wire n814_o;
  wire [3:0] n816_o;
  wire n824_o;
  wire n825_o;
  wire n826_o;
  wire n827_o;
  wire n828_o;
  wire [2:0] n832_o;
  wire n834_o;
  wire n836_o;
  wire n838_o;
  wire n840_o;
  wire [3:0] n841_o;
  reg [3:0] n847_o;
  wire n851_o;
  wire n853_o;
  wire n854_o;
  wire n856_o;
  wire n857_o;
  wire n859_o;
  wire n860_o;
  wire n862_o;
  wire n863_o;
  wire n865_o;
  wire n866_o;
  wire n868_o;
  wire n869_o;
  wire n871_o;
  wire n872_o;
  wire n874_o;
  wire n876_o;
  wire n877_o;
  wire n879_o;
  wire n880_o;
  wire n882_o;
  wire n883_o;
  wire n885_o;
  wire n887_o;
  wire n888_o;
  wire [2:0] n889_o;
  reg [1:0] n894_o;
  wire [15:0] n896_o;
  reg [15:0] n897_q;
  reg [4:0] n898_q;
  wire [28:0] n899_o;
  reg [28:0] n900_q;
  reg [3:0] n901_q;
  reg n902_q;
  reg [3:0] n903_q;
  reg [1:0] n904_q;
  reg n905_q;
  reg [3:0] n906_q;
  wire [1:0] n907_o;
  reg [1:0] n908_q;
  reg n909_q;
  reg n910_q;
  assign ctrl_o = ctrl;
  assign irq_vec_o = irq_vec;
  assign imm_o = n154_o;
  /* core/neo430_control.vhd:64:10  */
  assign ir = n897_q; // (signal)
  /* core/neo430_control.vhd:65:10  */
  assign ir_wren = n681_o; // (signal)
  /* core/neo430_control.vhd:68:10  */
  assign branch_taken = n140_o; // (signal)
  /* core/neo430_control.vhd:76:10  */
  assign state = n898_q; // (signal)
  /* core/neo430_control.vhd:76:17  */
  assign state_nxt = n701_o; // (signal)
  /* core/neo430_control.vhd:77:10  */
  assign ctrl_nxt = n899_o; // (signal)
  /* core/neo430_control.vhd:77:20  */
  assign ctrl = n900_q; // (signal)
  /* core/neo430_control.vhd:78:10  */
  assign am_nxt = n750_o; // (signal)
  /* core/neo430_control.vhd:78:18  */
  assign am = n901_q; // (signal)
  /* core/neo430_control.vhd:79:10  */
  assign mem_rd = n753_o; // (signal)
  /* core/neo430_control.vhd:79:18  */
  assign mem_rd_ff = n902_q; // (signal)
  /* core/neo430_control.vhd:80:10  */
  assign src_nxt = n755_o; // (signal)
  /* core/neo430_control.vhd:80:19  */
  assign src = n903_q; // (signal)
  /* core/neo430_control.vhd:81:10  */
  assign sam_nxt = n757_o; // (signal)
  /* core/neo430_control.vhd:81:19  */
  assign sam = n904_q; // (signal)
  /* core/neo430_control.vhd:84:10  */
  assign irq_fire = n828_o; // (signal)
  /* core/neo430_control.vhd:85:10  */
  assign irq_start = n905_q; // (signal)
  /* core/neo430_control.vhd:85:21  */
  assign irq_ack = n760_o; // (signal)
  /* core/neo430_control.vhd:86:10  */
  assign irq_ack_mask = n847_o; // (signal)
  /* core/neo430_control.vhd:86:24  */
  assign irq_buf = n906_q; // (signal)
  /* core/neo430_control.vhd:87:10  */
  assign irq_vec_nxt = n894_o; // (signal)
  /* core/neo430_control.vhd:87:23  */
  assign irq_vec = n908_q; // (signal)
  /* core/neo430_control.vhd:88:10  */
  assign i_flag_ff0 = n909_q; // (signal)
  /* core/neo430_control.vhd:88:22  */
  assign i_flag_ff1 = n910_q; // (signal)
  /* core/neo430_control.vhd:96:17  */
  assign n106_o = instr_i[12:10];
  /* core/neo430_control.vhd:97:51  */
  assign n107_o = sreg_i[1];
  /* core/neo430_control.vhd:97:41  */
  assign n108_o = ~n107_o;
  /* core/neo430_control.vhd:97:7  */
  assign n110_o = n106_o == 3'b000;
  /* core/neo430_control.vhd:98:47  */
  assign n111_o = sreg_i[1];
  /* core/neo430_control.vhd:98:7  */
  assign n113_o = n106_o == 3'b001;
  /* core/neo430_control.vhd:99:51  */
  assign n114_o = sreg_i[0];
  /* core/neo430_control.vhd:99:41  */
  assign n115_o = ~n114_o;
  /* core/neo430_control.vhd:99:7  */
  assign n117_o = n106_o == 3'b010;
  /* core/neo430_control.vhd:100:47  */
  assign n118_o = sreg_i[0];
  /* core/neo430_control.vhd:100:7  */
  assign n120_o = n106_o == 3'b011;
  /* core/neo430_control.vhd:101:47  */
  assign n121_o = sreg_i[2];
  /* core/neo430_control.vhd:101:7  */
  assign n123_o = n106_o == 3'b100;
  /* core/neo430_control.vhd:102:52  */
  assign n124_o = sreg_i[2];
  /* core/neo430_control.vhd:102:73  */
  assign n125_o = sreg_i[8];
  /* core/neo430_control.vhd:102:63  */
  assign n126_o = n124_o ^ n125_o;
  /* core/neo430_control.vhd:102:41  */
  assign n127_o = ~n126_o;
  /* core/neo430_control.vhd:102:7  */
  assign n129_o = n106_o == 3'b101;
  /* core/neo430_control.vhd:103:47  */
  assign n130_o = sreg_i[2];
  /* core/neo430_control.vhd:103:68  */
  assign n131_o = sreg_i[8];
  /* core/neo430_control.vhd:103:58  */
  assign n132_o = n130_o ^ n131_o;
  /* core/neo430_control.vhd:103:7  */
  assign n134_o = n106_o == 3'b110;
  /* core/neo430_control.vhd:104:7  */
  assign n136_o = n106_o == 3'b111;
  assign n137_o = {n136_o, n134_o, n129_o, n123_o, n120_o, n117_o, n113_o, n110_o};
  /* core/neo430_control.vhd:96:5  */
  always @*
    case (n137_o)
      8'b10000000: n140_o = 1'b1;
      8'b01000000: n140_o = n132_o;
      8'b00100000: n140_o = n127_o;
      8'b00010000: n140_o = n121_o;
      8'b00001000: n140_o = n118_o;
      8'b00000100: n140_o = n115_o;
      8'b00000010: n140_o = n111_o;
      8'b00000001: n140_o = n108_o;
      default: n140_o = 1'b0;
    endcase
  /* core/neo430_control.vhd:110:14  */
  assign n142_o = ir[9];
  /* core/neo430_control.vhd:110:22  */
  assign n143_o = ir[9];
  /* core/neo430_control.vhd:110:18  */
  assign n144_o = {n142_o, n143_o};
  /* core/neo430_control.vhd:110:30  */
  assign n145_o = ir[9];
  /* core/neo430_control.vhd:110:26  */
  assign n146_o = {n144_o, n145_o};
  /* core/neo430_control.vhd:110:38  */
  assign n147_o = ir[9];
  /* core/neo430_control.vhd:110:34  */
  assign n148_o = {n146_o, n147_o};
  /* core/neo430_control.vhd:110:46  */
  assign n149_o = ir[9];
  /* core/neo430_control.vhd:110:42  */
  assign n150_o = {n148_o, n149_o};
  /* core/neo430_control.vhd:110:54  */
  assign n151_o = ir[9:0];
  /* core/neo430_control.vhd:110:50  */
  assign n152_o = {n150_o, n151_o};
  /* core/neo430_control.vhd:110:67  */
  assign n154_o = {n152_o, 1'b0};
  /* core/neo430_control.vhd:118:15  */
  assign n156_o = ~rst_i;
  /* core/neo430_control.vhd:146:11  */
  assign n173_o = ir[15:12];
  /* core/neo430_control.vhd:146:26  */
  assign n175_o = n173_o == 4'b1010;
  /* core/neo430_control.vhd:147:7  */
  assign n178_o = ~n183_o;
  /* core/neo430_control.vhd:147:7  */
  assign n179_o = n178_o | 1'b0;
  /* core/neo430_control.vhd:147:7  */
  always @*
    if (!n179_o)
      $fatal(1, "assertion failure n180");
  /* core/neo430_control.vhd:146:5  */
  assign n183_o = n175_o ? 1'b1 : 1'b0;
  assign n192_o = n190_o[0];
  /* core/neo430_control.vhd:175:61  */
  assign n193_o = ctrl[18:15];
  /* core/neo430_control.vhd:179:36  */
  assign n201_o = ctrl[19];
  /* core/neo430_control.vhd:183:11  */
  assign n202_o = ir[15:9];
  /* core/neo430_control.vhd:183:25  */
  assign n204_o = n202_o == 7'b0001001;
  /* core/neo430_control.vhd:183:5  */
  assign n207_o = n204_o ? 1'b1 : 1'b0;
  /* core/neo430_control.vhd:190:13  */
  assign n209_o = ctrl[18:15];
  /* core/neo430_control.vhd:190:54  */
  assign n211_o = n209_o == 4'b0100;
  /* core/neo430_control.vhd:190:5  */
  assign n214_o = n211_o ? 1'b1 : 1'b0;
  /* core/neo430_control.vhd:196:11  */
  assign n216_o = ir[15:12];
  /* core/neo430_control.vhd:196:26  */
  assign n218_o = n216_o == 4'b1001;
  /* core/neo430_control.vhd:196:45  */
  assign n219_o = ir[15:12];
  /* core/neo430_control.vhd:196:60  */
  assign n221_o = n219_o == 4'b1011;
  /* core/neo430_control.vhd:196:39  */
  assign n222_o = n218_o | n221_o;
  /* core/neo430_control.vhd:196:5  */
  assign n225_o = n222_o ? 1'b0 : 1'b1;
  /* core/neo430_control.vhd:203:7  */
  assign n231_o = state == 5'b00000;
  /* core/neo430_control.vhd:221:22  */
  assign n236_o = sreg_i[4];
  /* core/neo430_control.vhd:221:33  */
  assign n237_o = ~n236_o;
  /* core/neo430_control.vhd:221:9  */
  assign n241_o = n237_o ? 5'b00010 : state;
  assign n242_o = n190_o[8];
  /* core/neo430_control.vhd:221:9  */
  assign n243_o = n237_o ? 1'b1 : n242_o;
  /* core/neo430_control.vhd:221:9  */
  assign n244_o = n237_o ? 1'b1 : mem_rd_ff;
  /* core/neo430_control.vhd:219:9  */
  assign n246_o = irq_start ? 5'b10010 : n241_o;
  assign n247_o = n190_o[8];
  /* core/neo430_control.vhd:219:9  */
  assign n248_o = irq_start ? n247_o : n243_o;
  /* core/neo430_control.vhd:219:9  */
  assign n249_o = irq_start ? mem_rd_ff : n244_o;
  /* core/neo430_control.vhd:211:7  */
  assign n251_o = state == 5'b00001;
  /* core/neo430_control.vhd:227:7  */
  assign n253_o = state == 5'b00010;
  /* core/neo430_control.vhd:235:43  */
  assign n254_o = instr_i[6];
  /* core/neo430_control.vhd:236:27  */
  assign n255_o = instr_i[5:4];
  /* core/neo430_control.vhd:241:20  */
  assign n258_o = instr_i[15:14];
  /* core/neo430_control.vhd:241:35  */
  assign n260_o = n258_o == 2'b00;
  /* core/neo430_control.vhd:242:22  */
  assign n261_o = instr_i[13];
  /* core/neo430_control.vhd:247:25  */
  assign n262_o = instr_i[12:10];
  /* core/neo430_control.vhd:247:40  */
  assign n264_o = n262_o == 3'b100;
  /* core/neo430_control.vhd:249:33  */
  assign n265_o = instr_i[4];
  /* core/neo430_control.vhd:249:47  */
  assign n266_o = instr_i[5];
  /* core/neo430_control.vhd:249:37  */
  assign n267_o = n265_o | n266_o;
  /* core/neo430_control.vhd:251:24  */
  assign n269_o = instr_i[3:0];
  /* core/neo430_control.vhd:251:37  */
  assign n271_o = n269_o == 4'b0011;
  /* core/neo430_control.vhd:251:61  */
  assign n272_o = instr_i[3:0];
  /* core/neo430_control.vhd:251:74  */
  assign n274_o = n272_o == 4'b0010;
  /* core/neo430_control.vhd:251:98  */
  assign n275_o = instr_i[5];
  /* core/neo430_control.vhd:251:86  */
  assign n276_o = n275_o & n274_o;
  /* core/neo430_control.vhd:251:49  */
  assign n277_o = n271_o | n276_o;
  /* core/neo430_control.vhd:254:44  */
  assign n279_o = instr_i[5:4];
  /* core/neo430_control.vhd:251:13  */
  assign n280_o = n277_o ? 2'b00 : n279_o;
  /* core/neo430_control.vhd:256:31  */
  assign n281_o = instr_i[3:0];
  /* core/neo430_control.vhd:257:24  */
  assign n282_o = instr_i[15:9];
  /* core/neo430_control.vhd:257:38  */
  assign n284_o = n282_o != 7'b0001001;
  /* core/neo430_control.vhd:258:81  */
  assign n285_o = instr_i[8:7];
  /* core/neo430_control.vhd:258:72  */
  assign n287_o = {2'b00, n285_o};
  /* core/neo430_control.vhd:257:13  */
  assign n289_o = n284_o ? n287_o : 4'b0100;
  /* core/neo430_control.vhd:262:25  */
  assign n290_o = instr_i[9:7];
  /* core/neo430_control.vhd:263:15  */
  assign n292_o = n290_o == 3'b100;
  /* core/neo430_control.vhd:264:15  */
  assign n294_o = n290_o == 3'b101;
  /* core/neo430_control.vhd:265:15  */
  assign n296_o = n290_o == 3'b110;
  /* core/neo430_control.vhd:266:15  */
  assign n298_o = n290_o == 3'b111;
  assign n299_o = {n298_o, n296_o, n294_o, n292_o};
  /* core/neo430_control.vhd:262:13  */
  always @*
    case (n299_o)
      4'b1000: n305_o = 5'b00001;
      4'b0100: n305_o = 5'b01110;
      4'b0010: n305_o = 5'b00100;
      4'b0001: n305_o = 5'b00100;
      default: n305_o = 5'b00100;
    endcase
  /* core/neo430_control.vhd:247:11  */
  assign n307_o = n264_o ? n305_o : 5'b00001;
  /* core/neo430_control.vhd:247:11  */
  assign n308_o = n264_o ? n289_o : n193_o;
  assign n309_o = {1'b0, n280_o, n267_o};
  /* core/neo430_control.vhd:247:11  */
  assign n310_o = n264_o ? n309_o : am;
  /* core/neo430_control.vhd:247:11  */
  assign n311_o = n264_o ? n281_o : src;
  /* core/neo430_control.vhd:242:11  */
  assign n313_o = n261_o ? 5'b00001 : n307_o;
  assign n314_o = n190_o[8];
  /* core/neo430_control.vhd:241:9  */
  assign n315_o = n343_o ? branch_taken : n314_o;
  /* core/neo430_control.vhd:242:11  */
  assign n316_o = n261_o ? n193_o : n308_o;
  /* core/neo430_control.vhd:242:11  */
  assign n317_o = n261_o ? am : n310_o;
  /* core/neo430_control.vhd:242:11  */
  assign n318_o = n261_o ? src : n311_o;
  /* core/neo430_control.vhd:278:22  */
  assign n320_o = instr_i[11:8];
  /* core/neo430_control.vhd:278:36  */
  assign n322_o = n320_o == 4'b0011;
  /* core/neo430_control.vhd:278:60  */
  assign n323_o = instr_i[11:8];
  /* core/neo430_control.vhd:278:74  */
  assign n325_o = n323_o == 4'b0010;
  /* core/neo430_control.vhd:278:98  */
  assign n326_o = instr_i[5];
  /* core/neo430_control.vhd:278:86  */
  assign n327_o = n326_o & n325_o;
  /* core/neo430_control.vhd:278:48  */
  assign n328_o = n322_o | n327_o;
  /* core/neo430_control.vhd:281:42  */
  assign n330_o = instr_i[5:4];
  /* core/neo430_control.vhd:278:11  */
  assign n331_o = n328_o ? 2'b00 : n330_o;
  /* core/neo430_control.vhd:283:31  */
  assign n332_o = instr_i[7];
  /* core/neo430_control.vhd:284:70  */
  assign n333_o = instr_i[15:12];
  /* core/neo430_control.vhd:285:29  */
  assign n334_o = instr_i[11:8];
  /* core/neo430_control.vhd:286:22  */
  assign n335_o = instr_i[15:12];
  /* core/neo430_control.vhd:286:37  */
  assign n337_o = n335_o == 4'b1010;
  /* core/neo430_control.vhd:286:11  */
  assign n340_o = n337_o ? 5'b00001 : 5'b00100;
  /* core/neo430_control.vhd:241:9  */
  assign n341_o = n260_o ? n313_o : n340_o;
  /* core/neo430_control.vhd:241:9  */
  assign n343_o = n261_o & n260_o;
  /* core/neo430_control.vhd:241:9  */
  assign n344_o = n260_o ? n316_o : n333_o;
  assign n345_o = {1'b1, n331_o, n332_o};
  /* core/neo430_control.vhd:241:9  */
  assign n346_o = n260_o ? n317_o : n345_o;
  /* core/neo430_control.vhd:241:9  */
  assign n347_o = n260_o ? n318_o : n334_o;
  /* core/neo430_control.vhd:232:7  */
  assign n349_o = state == 5'b00011;
  /* core/neo430_control.vhd:299:42  */
  assign n352_o = am[0];
  /* core/neo430_control.vhd:310:22  */
  assign n354_o = am[3];
  /* core/neo430_control.vhd:310:26  */
  assign n355_o = ~n354_o;
  /* core/neo430_control.vhd:310:13  */
  assign n358_o = n355_o ? 5'b01010 : 5'b00111;
  /* core/neo430_control.vhd:308:13  */
  assign n360_o = n207_o ? 5'b01011 : n358_o;
  /* core/neo430_control.vhd:302:11  */
  assign n362_o = am == 4'b0001;
  /* core/neo430_control.vhd:302:23  */
  assign n364_o = am == 4'b0000;
  /* core/neo430_control.vhd:302:23  */
  assign n365_o = n362_o | n364_o;
  /* core/neo430_control.vhd:302:32  */
  assign n367_o = am == 4'b1000;
  /* core/neo430_control.vhd:302:32  */
  assign n368_o = n365_o | n367_o;
  /* core/neo430_control.vhd:327:19  */
  assign n372_o = am[2:1];
  /* core/neo430_control.vhd:327:32  */
  assign n374_o = n372_o == 2'b00;
  /* core/neo430_control.vhd:327:13  */
  assign n377_o = n374_o ? 5'b00111 : 5'b00110;
  /* core/neo430_control.vhd:316:11  */
  assign n379_o = am == 4'b1001;
  /* core/neo430_control.vhd:316:25  */
  assign n381_o = am == 4'b1010;
  /* core/neo430_control.vhd:316:25  */
  assign n382_o = n379_o | n381_o;
  /* core/neo430_control.vhd:316:36  */
  assign n384_o = am == 4'b0010;
  /* core/neo430_control.vhd:316:36  */
  assign n385_o = n382_o | n384_o;
  /* core/neo430_control.vhd:316:46  */
  assign n387_o = am == 4'b0011;
  /* core/neo430_control.vhd:316:46  */
  assign n388_o = n385_o | n387_o;
  /* core/neo430_control.vhd:333:11  */
  assign n394_o = am == 4'b1011;
  /* core/neo430_control.vhd:344:11  */
  assign n397_o = am == 4'b0100;
  /* core/neo430_control.vhd:344:23  */
  assign n399_o = am == 4'b0101;
  /* core/neo430_control.vhd:344:23  */
  assign n400_o = n397_o | n399_o;
  /* core/neo430_control.vhd:344:32  */
  assign n402_o = am == 4'b1100;
  /* core/neo430_control.vhd:344:32  */
  assign n403_o = n400_o | n402_o;
  /* core/neo430_control.vhd:344:41  */
  assign n405_o = am == 4'b1101;
  /* core/neo430_control.vhd:344:41  */
  assign n406_o = n403_o | n405_o;
  /* core/neo430_control.vhd:360:19  */
  assign n408_o = ir[6];
  /* core/neo430_control.vhd:360:23  */
  assign n409_o = ~n408_o;
  /* core/neo430_control.vhd:360:38  */
  assign n411_o = src == 4'b0000;
  /* core/neo430_control.vhd:360:30  */
  assign n412_o = n409_o | n411_o;
  /* core/neo430_control.vhd:360:13  */
  assign n415_o = n412_o ? 3'b010 : 3'b001;
  assign n417_o = {n406_o, n394_o, n388_o, n368_o};
  /* core/neo430_control.vhd:301:9  */
  always @*
    case (n417_o)
      4'b1000: n421_o = 5'b00101;
      4'b0100: n421_o = 5'b00101;
      4'b0010: n421_o = n377_o;
      4'b0001: n421_o = n360_o;
      default: n421_o = 5'b00101;
    endcase
  /* core/neo430_control.vhd:301:9  */
  always @*
    case (n417_o)
      4'b1000: n422_o = src;
      4'b0100: n422_o = 4'b0000;
      4'b0010: n422_o = 4'b0000;
      4'b0001: n422_o = src;
      default: n422_o = src;
    endcase
  assign n423_o = n190_o[8];
  /* core/neo430_control.vhd:301:9  */
  always @*
    case (n417_o)
      4'b1000: n424_o = n423_o;
      4'b0100: n424_o = 1'b1;
      4'b0010: n424_o = 1'b1;
      4'b0001: n424_o = n423_o;
      default: n424_o = 1'b1;
    endcase
  assign n425_o = n190_o[13];
  /* core/neo430_control.vhd:301:9  */
  always @*
    case (n417_o)
      4'b1000: n426_o = n425_o;
      4'b0100: n426_o = n425_o;
      4'b0010: n426_o = n425_o;
      4'b0001: n426_o = 1'b1;
      default: n426_o = n425_o;
    endcase
  /* core/neo430_control.vhd:301:9  */
  always @*
    case (n417_o)
      4'b1000: n427_o = 3'b010;
      4'b0100: n427_o = 3'b010;
      4'b0010: n427_o = 3'b010;
      4'b0001: n427_o = 3'b010;
      default: n427_o = n415_o;
    endcase
  /* core/neo430_control.vhd:301:9  */
  always @*
    case (n417_o)
      4'b1000: n428_o = n352_o;
      4'b0100: n428_o = 1'b1;
      4'b0010: n428_o = n352_o;
      4'b0001: n428_o = n352_o;
      default: n428_o = n352_o;
    endcase
  /* core/neo430_control.vhd:301:9  */
  always @*
    case (n417_o)
      4'b1000: n429_o = 1'b1;
      4'b0100: n429_o = 1'b1;
      4'b0010: n429_o = 1'b1;
      4'b0001: n429_o = mem_rd_ff;
      default: n429_o = 1'b1;
    endcase
  /* core/neo430_control.vhd:301:9  */
  always @*
    case (n417_o)
      4'b1000: n432_o = 1'b0;
      4'b0100: n432_o = 1'b1;
      4'b0010: n432_o = 1'b0;
      4'b0001: n432_o = 1'b0;
      default: n432_o = 1'b0;
    endcase
  /* core/neo430_control.vhd:294:7  */
  assign n434_o = state == 5'b00100;
  /* core/neo430_control.vhd:398:21  */
  assign n439_o = am[3];
  /* core/neo430_control.vhd:398:25  */
  assign n440_o = ~n439_o;
  /* core/neo430_control.vhd:398:15  */
  assign n443_o = n440_o ? 5'b01010 : 5'b00111;
  /* core/neo430_control.vhd:395:13  */
  assign n445_o = n207_o ? 5'b01011 : n443_o;
  /* core/neo430_control.vhd:387:11  */
  assign n447_o = am == 4'b0100;
  /* core/neo430_control.vhd:387:23  */
  assign n449_o = am == 4'b0101;
  /* core/neo430_control.vhd:387:23  */
  assign n450_o = n447_o | n449_o;
  /* core/neo430_control.vhd:387:32  */
  assign n452_o = am == 4'b1100;
  /* core/neo430_control.vhd:387:32  */
  assign n453_o = n450_o | n452_o;
  /* core/neo430_control.vhd:387:43  */
  assign n455_o = am == 4'b0110;
  /* core/neo430_control.vhd:387:43  */
  assign n456_o = n453_o | n455_o;
  /* core/neo430_control.vhd:387:54  */
  assign n458_o = am == 4'b0111;
  /* core/neo430_control.vhd:387:54  */
  assign n459_o = n456_o | n458_o;
  /* core/neo430_control.vhd:387:63  */
  assign n461_o = am == 4'b1110;
  /* core/neo430_control.vhd:387:63  */
  assign n462_o = n459_o | n461_o;
  /* core/neo430_control.vhd:405:11  */
  assign n469_o = am == 4'b1101;
  /* core/neo430_control.vhd:405:24  */
  assign n471_o = am == 4'b1111;
  /* core/neo430_control.vhd:405:24  */
  assign n472_o = n469_o | n471_o;
  assign n475_o = {n472_o, n462_o};
  /* core/neo430_control.vhd:377:9  */
  always @*
    case (n475_o)
      2'b10: n478_o = 5'b00111;
      2'b01: n478_o = n445_o;
      default: n478_o = 5'b00110;
    endcase
  assign n479_o = n190_o[8];
  /* core/neo430_control.vhd:377:9  */
  always @*
    case (n475_o)
      2'b10: n480_o = 1'b1;
      2'b01: n480_o = n479_o;
      default: n480_o = 1'b1;
    endcase
  assign n481_o = n190_o[12];
  /* core/neo430_control.vhd:377:9  */
  always @*
    case (n475_o)
      2'b10: n482_o = 1'b1;
      2'b01: n482_o = 1'b1;
      default: n482_o = n481_o;
    endcase
  assign n483_o = n190_o[13];
  /* core/neo430_control.vhd:377:9  */
  always @*
    case (n475_o)
      2'b10: n484_o = 1'b1;
      2'b01: n484_o = 1'b1;
      default: n484_o = n483_o;
    endcase
  assign n485_o = n190_o[24];
  /* core/neo430_control.vhd:377:9  */
  always @*
    case (n475_o)
      2'b10: n486_o = 1'b1;
      2'b01: n486_o = n485_o;
      default: n486_o = n485_o;
    endcase
  assign n487_o = n190_o[26];
  /* core/neo430_control.vhd:377:9  */
  always @*
    case (n475_o)
      2'b10: n488_o = n487_o;
      2'b01: n488_o = n487_o;
      default: n488_o = 1'b1;
    endcase
  /* core/neo430_control.vhd:377:9  */
  always @*
    case (n475_o)
      2'b10: n489_o = 1'b1;
      2'b01: n489_o = mem_rd_ff;
      default: n489_o = mem_rd_ff;
    endcase
  /* core/neo430_control.vhd:377:9  */
  always @*
    case (n475_o)
      2'b10: n492_o = 1'b0;
      2'b01: n492_o = 1'b0;
      default: n492_o = 1'b1;
    endcase
  /* core/neo430_control.vhd:370:7  */
  assign n494_o = state == 5'b00101;
  /* core/neo430_control.vhd:430:7  */
  assign n500_o = state == 5'b00110;
  /* core/neo430_control.vhd:447:61  */
  assign n501_o = ir[3:0];
  /* core/neo430_control.vhd:458:42  */
  assign n505_o = ir[7];
  /* core/neo430_control.vhd:462:21  */
  assign n507_o = ctrl[18:15];
  /* core/neo430_control.vhd:462:62  */
  assign n509_o = n507_o != 4'b0100;
  /* core/neo430_control.vhd:462:13  */
  assign n512_o = n509_o ? 1'b1 : 1'b0;
  /* core/neo430_control.vhd:452:11  */
  assign n514_o = am == 4'b1001;
  /* core/neo430_control.vhd:452:23  */
  assign n516_o = am == 4'b1011;
  /* core/neo430_control.vhd:452:23  */
  assign n517_o = n514_o | n516_o;
  /* core/neo430_control.vhd:452:32  */
  assign n519_o = am == 4'b1101;
  /* core/neo430_control.vhd:452:32  */
  assign n520_o = n517_o | n519_o;
  /* core/neo430_control.vhd:452:41  */
  assign n522_o = am == 4'b1111;
  /* core/neo430_control.vhd:452:41  */
  assign n523_o = n520_o | n522_o;
  /* core/neo430_control.vhd:470:19  */
  assign n526_o = am[2:1];
  /* core/neo430_control.vhd:470:32  */
  assign n528_o = n526_o == 2'b01;
  /* core/neo430_control.vhd:470:13  */
  assign n531_o = n528_o ? 5'b01000 : 5'b01010;
  /* core/neo430_control.vhd:451:9  */
  always @*
    case (n523_o)
      1'b1: n533_o = 5'b01000;
      default: n533_o = n531_o;
    endcase
  assign n534_o = n524_o[0];
  /* core/neo430_control.vhd:451:9  */
  always @*
    case (n523_o)
      1'b1: n535_o = n505_o;
      default: n535_o = n534_o;
    endcase
  assign n536_o = n524_o[1];
  /* core/neo430_control.vhd:451:9  */
  always @*
    case (n523_o)
      1'b1: n537_o = 1'b0;
      default: n537_o = n536_o;
    endcase
  assign n538_o = n190_o[14];
  /* core/neo430_control.vhd:451:9  */
  always @*
    case (n523_o)
      1'b1: n539_o = n538_o;
      default: n539_o = 1'b1;
    endcase
  assign n540_o = n190_o[26];
  /* core/neo430_control.vhd:451:9  */
  always @*
    case (n523_o)
      1'b1: n541_o = 1'b1;
      default: n541_o = n540_o;
    endcase
  /* core/neo430_control.vhd:451:9  */
  always @*
    case (n523_o)
      1'b1: n543_o = n512_o;
      default: n543_o = 1'b0;
    endcase
  /* core/neo430_control.vhd:444:7  */
  assign n545_o = state == 5'b00111;
  /* core/neo430_control.vhd:491:23  */
  assign n548_o = am[3];
  /* core/neo430_control.vhd:491:33  */
  assign n549_o = am[0];
  /* core/neo430_control.vhd:491:27  */
  assign n550_o = n548_o & n549_o;
  /* core/neo430_control.vhd:491:61  */
  assign n551_o = ~n214_o;
  /* core/neo430_control.vhd:491:45  */
  assign n552_o = n551_o & n550_o;
  /* core/neo430_control.vhd:491:13  */
  assign n555_o = n552_o ? 5'b01001 : 5'b01010;
  /* core/neo430_control.vhd:489:13  */
  assign n557_o = n207_o ? 5'b01011 : n555_o;
  /* core/neo430_control.vhd:483:11  */
  assign n559_o = am == 4'b0010;
  /* core/neo430_control.vhd:483:23  */
  assign n561_o = am == 4'b0011;
  /* core/neo430_control.vhd:483:23  */
  assign n562_o = n559_o | n561_o;
  /* core/neo430_control.vhd:483:32  */
  assign n564_o = am == 4'b1010;
  /* core/neo430_control.vhd:483:32  */
  assign n565_o = n562_o | n564_o;
  /* core/neo430_control.vhd:483:41  */
  assign n567_o = am == 4'b1011;
  /* core/neo430_control.vhd:483:41  */
  assign n568_o = n565_o | n567_o;
  /* core/neo430_control.vhd:500:13  */
  assign n572_o = n214_o ? 5'b01010 : 5'b01001;
  /* core/neo430_control.vhd:497:11  */
  assign n574_o = am == 4'b1001;
  /* core/neo430_control.vhd:511:13  */
  assign n577_o = n214_o ? 5'b01010 : 5'b01001;
  assign n578_o = {n574_o, n568_o};
  /* core/neo430_control.vhd:482:9  */
  always @*
    case (n578_o)
      2'b10: n579_o = n572_o;
      2'b01: n579_o = n557_o;
      default: n579_o = n577_o;
    endcase
  assign n580_o = n190_o[12];
  /* core/neo430_control.vhd:482:9  */
  always @*
    case (n578_o)
      2'b10: n581_o = n580_o;
      2'b01: n581_o = 1'b1;
      default: n581_o = n580_o;
    endcase
  assign n582_o = n190_o[13];
  /* core/neo430_control.vhd:482:9  */
  always @*
    case (n578_o)
      2'b10: n583_o = 1'b1;
      2'b01: n583_o = 1'b1;
      default: n583_o = n582_o;
    endcase
  /* core/neo430_control.vhd:477:7  */
  assign n585_o = state == 5'b01000;
  /* core/neo430_control.vhd:518:7  */
  assign n589_o = state == 5'b01001;
  /* core/neo430_control.vhd:526:61  */
  assign n590_o = ir[3:0];
  /* core/neo430_control.vhd:527:36  */
  assign n591_o = ~n207_o;
  /* core/neo430_control.vhd:528:15  */
  assign n592_o = am[0];
  /* core/neo430_control.vhd:528:19  */
  assign n593_o = ~n592_o;
  assign n594_o = n190_o[8];
  /* core/neo430_control.vhd:528:9  */
  assign n595_o = n593_o ? n225_o : n594_o;
  assign n596_o = n190_o[27];
  /* core/neo430_control.vhd:528:9  */
  assign n597_o = n593_o ? n596_o : n225_o;
  /* core/neo430_control.vhd:524:7  */
  assign n599_o = state == 5'b01010;
  /* core/neo430_control.vhd:545:15  */
  assign n606_o = ir[7];
  /* core/neo430_control.vhd:545:9  */
  assign n609_o = n606_o ? 5'b01100 : 5'b01101;
  /* core/neo430_control.vhd:536:7  */
  assign n611_o = state == 5'b01011;
  /* core/neo430_control.vhd:551:7  */
  assign n615_o = state == 5'b01100;
  /* core/neo430_control.vhd:558:7  */
  assign n618_o = state == 5'b01101;
  /* core/neo430_control.vhd:564:7  */
  assign n625_o = state == 5'b01110;
  /* core/neo430_control.vhd:575:7  */
  assign n634_o = state == 5'b01111;
  /* core/neo430_control.vhd:587:7  */
  assign n640_o = state == 5'b10000;
  /* core/neo430_control.vhd:595:7  */
  assign n643_o = state == 5'b10001;
  /* core/neo430_control.vhd:602:7  */
  assign n651_o = state == 5'b10010;
  /* core/neo430_control.vhd:614:7  */
  assign n654_o = state == 5'b10011;
  /* core/neo430_control.vhd:620:7  */
  assign n662_o = state == 5'b10100;
  /* core/neo430_control.vhd:631:7  */
  assign n669_o = state == 5'b10101;
  /* core/neo430_control.vhd:642:7  */
  assign n674_o = state == 5'b10110;
  /* core/neo430_control.vhd:649:7  */
  assign n677_o = state == 5'b10111;
  assign n678_o = {n677_o, n674_o, n669_o, n662_o, n654_o, n651_o, n643_o, n640_o, n634_o, n625_o, n618_o, n615_o, n611_o, n599_o, n589_o, n585_o, n545_o, n500_o, n494_o, n434_o, n349_o, n253_o, n251_o, n231_o};
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n681_o = 1'b0;
      24'b010000000000000000000000: n681_o = 1'b0;
      24'b001000000000000000000000: n681_o = 1'b0;
      24'b000100000000000000000000: n681_o = 1'b0;
      24'b000010000000000000000000: n681_o = 1'b0;
      24'b000001000000000000000000: n681_o = 1'b0;
      24'b000000100000000000000000: n681_o = 1'b0;
      24'b000000010000000000000000: n681_o = 1'b0;
      24'b000000001000000000000000: n681_o = 1'b0;
      24'b000000000100000000000000: n681_o = 1'b0;
      24'b000000000010000000000000: n681_o = 1'b0;
      24'b000000000001000000000000: n681_o = 1'b0;
      24'b000000000000100000000000: n681_o = 1'b0;
      24'b000000000000010000000000: n681_o = 1'b0;
      24'b000000000000001000000000: n681_o = 1'b0;
      24'b000000000000000100000000: n681_o = 1'b0;
      24'b000000000000000010000000: n681_o = 1'b0;
      24'b000000000000000001000000: n681_o = 1'b0;
      24'b000000000000000000100000: n681_o = 1'b0;
      24'b000000000000000000010000: n681_o = 1'b0;
      24'b000000000000000000001000: n681_o = 1'b1;
      24'b000000000000000000000100: n681_o = 1'b0;
      24'b000000000000000000000010: n681_o = 1'b0;
      24'b000000000000000000000001: n681_o = 1'b0;
      default: n681_o = 1'b0;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n701_o = 5'b00001;
      24'b010000000000000000000000: n701_o = 5'b10111;
      24'b001000000000000000000000: n701_o = 5'b10110;
      24'b000100000000000000000000: n701_o = 5'b10101;
      24'b000010000000000000000000: n701_o = 5'b10100;
      24'b000001000000000000000000: n701_o = 5'b10011;
      24'b000000100000000000000000: n701_o = 5'b00001;
      24'b000000010000000000000000: n701_o = 5'b10001;
      24'b000000001000000000000000: n701_o = 5'b10000;
      24'b000000000100000000000000: n701_o = 5'b01111;
      24'b000000000010000000000000: n701_o = 5'b00001;
      24'b000000000001000000000000: n701_o = 5'b01101;
      24'b000000000000100000000000: n701_o = n609_o;
      24'b000000000000010000000000: n701_o = 5'b00001;
      24'b000000000000001000000000: n701_o = 5'b01010;
      24'b000000000000000100000000: n701_o = n579_o;
      24'b000000000000000010000000: n701_o = n533_o;
      24'b000000000000000001000000: n701_o = 5'b00111;
      24'b000000000000000000100000: n701_o = n478_o;
      24'b000000000000000000010000: n701_o = n421_o;
      24'b000000000000000000001000: n701_o = n341_o;
      24'b000000000000000000000100: n701_o = 5'b00011;
      24'b000000000000000000000010: n701_o = n246_o;
      24'b000000000000000000000001: n701_o = 5'b00001;
      default: n701_o = 5'b00000;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n702_o = n192_o;
      24'b010000000000000000000000: n702_o = n192_o;
      24'b001000000000000000000000: n702_o = n192_o;
      24'b000100000000000000000000: n702_o = 1'b1;
      24'b000010000000000000000000: n702_o = n192_o;
      24'b000001000000000000000000: n702_o = 1'b1;
      24'b000000100000000000000000: n702_o = n192_o;
      24'b000000010000000000000000: n702_o = n192_o;
      24'b000000001000000000000000: n702_o = 1'b1;
      24'b000000000100000000000000: n702_o = 1'b1;
      24'b000000000010000000000000: n702_o = n192_o;
      24'b000000000001000000000000: n702_o = n192_o;
      24'b000000000000100000000000: n702_o = 1'b1;
      24'b000000000000010000000000: n702_o = n192_o;
      24'b000000000000001000000000: n702_o = n192_o;
      24'b000000000000000100000000: n702_o = n192_o;
      24'b000000000000000010000000: n702_o = n192_o;
      24'b000000000000000001000000: n702_o = n192_o;
      24'b000000000000000000100000: n702_o = 1'b1;
      24'b000000000000000000010000: n702_o = 1'b1;
      24'b000000000000000000001000: n702_o = 1'b1;
      24'b000000000000000000000100: n702_o = n192_o;
      24'b000000000000000000000010: n702_o = 1'b1;
      24'b000000000000000000000001: n702_o = n192_o;
      default: n702_o = n192_o;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n703_o = 4'b0000;
      24'b010000000000000000000000: n703_o = src;
      24'b001000000000000000000000: n703_o = 4'b0010;
      24'b000100000000000000000000: n703_o = 4'b0001;
      24'b000010000000000000000000: n703_o = 4'b0000;
      24'b000001000000000000000000: n703_o = 4'b0001;
      24'b000000100000000000000000: n703_o = 4'b0000;
      24'b000000010000000000000000: n703_o = 4'b0010;
      24'b000000001000000000000000: n703_o = 4'b0001;
      24'b000000000100000000000000: n703_o = 4'b0001;
      24'b000000000010000000000000: n703_o = src;
      24'b000000000001000000000000: n703_o = 4'b0000;
      24'b000000000000100000000000: n703_o = 4'b0001;
      24'b000000000000010000000000: n703_o = n590_o;
      24'b000000000000001000000000: n703_o = src;
      24'b000000000000000100000000: n703_o = src;
      24'b000000000000000010000000: n703_o = n501_o;
      24'b000000000000000001000000: n703_o = src;
      24'b000000000000000000100000: n703_o = 4'b0000;
      24'b000000000000000000010000: n703_o = n422_o;
      24'b000000000000000000001000: n703_o = 4'b0000;
      24'b000000000000000000000100: n703_o = src;
      24'b000000000000000000000010: n703_o = 4'b0000;
      24'b000000000000000000000001: n703_o = 4'b0000;
      default: n703_o = src;
    endcase
  assign n704_o = sam[0];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n705_o = n704_o;
      24'b010000000000000000000000: n705_o = n704_o;
      24'b001000000000000000000000: n705_o = n704_o;
      24'b000100000000000000000000: n705_o = n704_o;
      24'b000010000000000000000000: n705_o = n704_o;
      24'b000001000000000000000000: n705_o = n704_o;
      24'b000000100000000000000000: n705_o = n704_o;
      24'b000000010000000000000000: n705_o = n704_o;
      24'b000000001000000000000000: n705_o = n704_o;
      24'b000000000100000000000000: n705_o = n704_o;
      24'b000000000010000000000000: n705_o = n704_o;
      24'b000000000001000000000000: n705_o = n704_o;
      24'b000000000000100000000000: n705_o = n704_o;
      24'b000000000000010000000000: n705_o = n704_o;
      24'b000000000000001000000000: n705_o = n704_o;
      24'b000000000000000100000000: n705_o = n704_o;
      24'b000000000000000010000000: n705_o = n535_o;
      24'b000000000000000001000000: n705_o = n704_o;
      24'b000000000000000000100000: n705_o = n704_o;
      24'b000000000000000000010000: n705_o = n704_o;
      24'b000000000000000000001000: n705_o = n704_o;
      24'b000000000000000000000100: n705_o = n704_o;
      24'b000000000000000000000010: n705_o = n704_o;
      24'b000000000000000000000001: n705_o = n704_o;
      default: n705_o = n704_o;
    endcase
  assign n706_o = sam[1];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n707_o = n706_o;
      24'b010000000000000000000000: n707_o = n706_o;
      24'b001000000000000000000000: n707_o = n706_o;
      24'b000100000000000000000000: n707_o = n706_o;
      24'b000010000000000000000000: n707_o = n706_o;
      24'b000001000000000000000000: n707_o = n706_o;
      24'b000000100000000000000000: n707_o = n706_o;
      24'b000000010000000000000000: n707_o = n706_o;
      24'b000000001000000000000000: n707_o = n706_o;
      24'b000000000100000000000000: n707_o = n706_o;
      24'b000000000010000000000000: n707_o = n706_o;
      24'b000000000001000000000000: n707_o = n706_o;
      24'b000000000000100000000000: n707_o = n706_o;
      24'b000000000000010000000000: n707_o = n706_o;
      24'b000000000000001000000000: n707_o = n706_o;
      24'b000000000000000100000000: n707_o = n706_o;
      24'b000000000000000010000000: n707_o = n537_o;
      24'b000000000000000001000000: n707_o = n706_o;
      24'b000000000000000000100000: n707_o = n706_o;
      24'b000000000000000000010000: n707_o = n706_o;
      24'b000000000000000000001000: n707_o = n706_o;
      24'b000000000000000000000100: n707_o = n706_o;
      24'b000000000000000000000010: n707_o = n706_o;
      24'b000000000000000000000001: n707_o = n706_o;
      default: n707_o = n706_o;
    endcase
  assign n708_o = n190_o[7];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n709_o = n708_o;
      24'b010000000000000000000000: n709_o = n708_o;
      24'b001000000000000000000000: n709_o = n708_o;
      24'b000100000000000000000000: n709_o = n708_o;
      24'b000010000000000000000000: n709_o = n708_o;
      24'b000001000000000000000000: n709_o = n708_o;
      24'b000000100000000000000000: n709_o = n708_o;
      24'b000000010000000000000000: n709_o = n708_o;
      24'b000000001000000000000000: n709_o = n708_o;
      24'b000000000100000000000000: n709_o = n708_o;
      24'b000000000010000000000000: n709_o = n708_o;
      24'b000000000001000000000000: n709_o = n708_o;
      24'b000000000000100000000000: n709_o = n708_o;
      24'b000000000000010000000000: n709_o = n591_o;
      24'b000000000000001000000000: n709_o = n708_o;
      24'b000000000000000100000000: n709_o = n708_o;
      24'b000000000000000010000000: n709_o = n708_o;
      24'b000000000000000001000000: n709_o = n708_o;
      24'b000000000000000000100000: n709_o = n708_o;
      24'b000000000000000000010000: n709_o = n708_o;
      24'b000000000000000000001000: n709_o = n708_o;
      24'b000000000000000000000100: n709_o = n708_o;
      24'b000000000000000000000010: n709_o = n708_o;
      24'b000000000000000000000001: n709_o = n708_o;
      default: n709_o = n708_o;
    endcase
  assign n710_o = n190_o[8];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n711_o = 1'b1;
      24'b010000000000000000000000: n711_o = n710_o;
      24'b001000000000000000000000: n711_o = n710_o;
      24'b000100000000000000000000: n711_o = 1'b1;
      24'b000010000000000000000000: n711_o = n710_o;
      24'b000001000000000000000000: n711_o = 1'b1;
      24'b000000100000000000000000: n711_o = 1'b1;
      24'b000000010000000000000000: n711_o = 1'b1;
      24'b000000001000000000000000: n711_o = 1'b1;
      24'b000000000100000000000000: n711_o = 1'b1;
      24'b000000000010000000000000: n711_o = n710_o;
      24'b000000000001000000000000: n711_o = 1'b1;
      24'b000000000000100000000000: n711_o = 1'b1;
      24'b000000000000010000000000: n711_o = n595_o;
      24'b000000000000001000000000: n711_o = n710_o;
      24'b000000000000000100000000: n711_o = n710_o;
      24'b000000000000000010000000: n711_o = n710_o;
      24'b000000000000000001000000: n711_o = n710_o;
      24'b000000000000000000100000: n711_o = n480_o;
      24'b000000000000000000010000: n711_o = n424_o;
      24'b000000000000000000001000: n711_o = n315_o;
      24'b000000000000000000000100: n711_o = n710_o;
      24'b000000000000000000000010: n711_o = n248_o;
      24'b000000000000000000000001: n711_o = 1'b1;
      default: n711_o = n710_o;
    endcase
  assign n712_o = n190_o[9];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n713_o = n712_o;
      24'b010000000000000000000000: n713_o = n712_o;
      24'b001000000000000000000000: n713_o = n712_o;
      24'b000100000000000000000000: n713_o = n712_o;
      24'b000010000000000000000000: n713_o = n712_o;
      24'b000001000000000000000000: n713_o = 1'b1;
      24'b000000100000000000000000: n713_o = n712_o;
      24'b000000010000000000000000: n713_o = n712_o;
      24'b000000001000000000000000: n713_o = n712_o;
      24'b000000000100000000000000: n713_o = n712_o;
      24'b000000000010000000000000: n713_o = n712_o;
      24'b000000000001000000000000: n713_o = n712_o;
      24'b000000000000100000000000: n713_o = n712_o;
      24'b000000000000010000000000: n713_o = n712_o;
      24'b000000000000001000000000: n713_o = n712_o;
      24'b000000000000000100000000: n713_o = n712_o;
      24'b000000000000000010000000: n713_o = n712_o;
      24'b000000000000000001000000: n713_o = n712_o;
      24'b000000000000000000100000: n713_o = n712_o;
      24'b000000000000000000010000: n713_o = n712_o;
      24'b000000000000000000001000: n713_o = n712_o;
      24'b000000000000000000000100: n713_o = n712_o;
      24'b000000000000000000000010: n713_o = n712_o;
      24'b000000000000000000000001: n713_o = n712_o;
      default: n713_o = n712_o;
    endcase
  assign n714_o = n190_o[10];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n715_o = n714_o;
      24'b010000000000000000000000: n715_o = n714_o;
      24'b001000000000000000000000: n715_o = 1'b1;
      24'b000100000000000000000000: n715_o = n714_o;
      24'b000010000000000000000000: n715_o = n714_o;
      24'b000001000000000000000000: n715_o = n714_o;
      24'b000000100000000000000000: n715_o = n714_o;
      24'b000000010000000000000000: n715_o = n714_o;
      24'b000000001000000000000000: n715_o = n714_o;
      24'b000000000100000000000000: n715_o = n714_o;
      24'b000000000010000000000000: n715_o = n714_o;
      24'b000000000001000000000000: n715_o = n714_o;
      24'b000000000000100000000000: n715_o = n714_o;
      24'b000000000000010000000000: n715_o = n714_o;
      24'b000000000000001000000000: n715_o = n714_o;
      24'b000000000000000100000000: n715_o = n714_o;
      24'b000000000000000010000000: n715_o = n714_o;
      24'b000000000000000001000000: n715_o = n714_o;
      24'b000000000000000000100000: n715_o = n714_o;
      24'b000000000000000000010000: n715_o = n714_o;
      24'b000000000000000000001000: n715_o = n714_o;
      24'b000000000000000000000100: n715_o = n714_o;
      24'b000000000000000000000010: n715_o = n714_o;
      24'b000000000000000000000001: n715_o = n714_o;
      default: n715_o = n714_o;
    endcase
  assign n716_o = n190_o[11];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n717_o = n716_o;
      24'b010000000000000000000000: n717_o = n716_o;
      24'b001000000000000000000000: n717_o = n716_o;
      24'b000100000000000000000000: n717_o = n716_o;
      24'b000010000000000000000000: n717_o = n716_o;
      24'b000001000000000000000000: n717_o = n716_o;
      24'b000000100000000000000000: n717_o = n716_o;
      24'b000000010000000000000000: n717_o = n716_o;
      24'b000000001000000000000000: n717_o = n716_o;
      24'b000000000100000000000000: n717_o = n716_o;
      24'b000000000010000000000000: n717_o = n716_o;
      24'b000000000001000000000000: n717_o = n716_o;
      24'b000000000000100000000000: n717_o = n716_o;
      24'b000000000000010000000000: n717_o = n716_o;
      24'b000000000000001000000000: n717_o = n716_o;
      24'b000000000000000100000000: n717_o = n716_o;
      24'b000000000000000010000000: n717_o = n716_o;
      24'b000000000000000001000000: n717_o = n716_o;
      24'b000000000000000000100000: n717_o = n716_o;
      24'b000000000000000000010000: n717_o = n716_o;
      24'b000000000000000000001000: n717_o = n716_o;
      24'b000000000000000000000100: n717_o = n716_o;
      24'b000000000000000000000010: n717_o = n716_o;
      24'b000000000000000000000001: n717_o = 1'b1;
      default: n717_o = n716_o;
    endcase
  assign n718_o = n190_o[12];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n719_o = n718_o;
      24'b010000000000000000000000: n719_o = 1'b1;
      24'b001000000000000000000000: n719_o = n718_o;
      24'b000100000000000000000000: n719_o = n718_o;
      24'b000010000000000000000000: n719_o = n718_o;
      24'b000001000000000000000000: n719_o = n718_o;
      24'b000000100000000000000000: n719_o = n718_o;
      24'b000000010000000000000000: n719_o = 1'b1;
      24'b000000001000000000000000: n719_o = 1'b1;
      24'b000000000100000000000000: n719_o = n718_o;
      24'b000000000010000000000000: n719_o = n718_o;
      24'b000000000001000000000000: n719_o = n718_o;
      24'b000000000000100000000000: n719_o = n718_o;
      24'b000000000000010000000000: n719_o = n718_o;
      24'b000000000000001000000000: n719_o = 1'b1;
      24'b000000000000000100000000: n719_o = n581_o;
      24'b000000000000000010000000: n719_o = n718_o;
      24'b000000000000000001000000: n719_o = n718_o;
      24'b000000000000000000100000: n719_o = n482_o;
      24'b000000000000000000010000: n719_o = n718_o;
      24'b000000000000000000001000: n719_o = n718_o;
      24'b000000000000000000000100: n719_o = n718_o;
      24'b000000000000000000000010: n719_o = n718_o;
      24'b000000000000000000000001: n719_o = n718_o;
      default: n719_o = n718_o;
    endcase
  assign n720_o = n190_o[13];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n721_o = n720_o;
      24'b010000000000000000000000: n721_o = 1'b1;
      24'b001000000000000000000000: n721_o = 1'b1;
      24'b000100000000000000000000: n721_o = n720_o;
      24'b000010000000000000000000: n721_o = 1'b1;
      24'b000001000000000000000000: n721_o = n720_o;
      24'b000000100000000000000000: n721_o = n720_o;
      24'b000000010000000000000000: n721_o = 1'b1;
      24'b000000001000000000000000: n721_o = 1'b1;
      24'b000000000100000000000000: n721_o = n720_o;
      24'b000000000010000000000000: n721_o = n720_o;
      24'b000000000001000000000000: n721_o = 1'b1;
      24'b000000000000100000000000: n721_o = n720_o;
      24'b000000000000010000000000: n721_o = n720_o;
      24'b000000000000001000000000: n721_o = n720_o;
      24'b000000000000000100000000: n721_o = n583_o;
      24'b000000000000000010000000: n721_o = n720_o;
      24'b000000000000000001000000: n721_o = n720_o;
      24'b000000000000000000100000: n721_o = n484_o;
      24'b000000000000000000010000: n721_o = n426_o;
      24'b000000000000000000001000: n721_o = n720_o;
      24'b000000000000000000000100: n721_o = n720_o;
      24'b000000000000000000000010: n721_o = n720_o;
      24'b000000000000000000000001: n721_o = n720_o;
      default: n721_o = n720_o;
    endcase
  assign n722_o = n190_o[14];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n723_o = n722_o;
      24'b010000000000000000000000: n723_o = n722_o;
      24'b001000000000000000000000: n723_o = n722_o;
      24'b000100000000000000000000: n723_o = n722_o;
      24'b000010000000000000000000: n723_o = n722_o;
      24'b000001000000000000000000: n723_o = n722_o;
      24'b000000100000000000000000: n723_o = n722_o;
      24'b000000010000000000000000: n723_o = n722_o;
      24'b000000001000000000000000: n723_o = n722_o;
      24'b000000000100000000000000: n723_o = n722_o;
      24'b000000000010000000000000: n723_o = n722_o;
      24'b000000000001000000000000: n723_o = n722_o;
      24'b000000000000100000000000: n723_o = n722_o;
      24'b000000000000010000000000: n723_o = n722_o;
      24'b000000000000001000000000: n723_o = 1'b1;
      24'b000000000000000100000000: n723_o = n722_o;
      24'b000000000000000010000000: n723_o = n539_o;
      24'b000000000000000001000000: n723_o = n722_o;
      24'b000000000000000000100000: n723_o = n722_o;
      24'b000000000000000000010000: n723_o = n722_o;
      24'b000000000000000000001000: n723_o = n722_o;
      24'b000000000000000000000100: n723_o = n722_o;
      24'b000000000000000000000010: n723_o = n722_o;
      24'b000000000000000000000001: n723_o = n722_o;
      default: n723_o = n722_o;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n724_o = n193_o;
      24'b010000000000000000000000: n724_o = n193_o;
      24'b001000000000000000000000: n724_o = n193_o;
      24'b000100000000000000000000: n724_o = n193_o;
      24'b000010000000000000000000: n724_o = n193_o;
      24'b000001000000000000000000: n724_o = 4'b0100;
      24'b000000100000000000000000: n724_o = n193_o;
      24'b000000010000000000000000: n724_o = n193_o;
      24'b000000001000000000000000: n724_o = n193_o;
      24'b000000000100000000000000: n724_o = 4'b0100;
      24'b000000000010000000000000: n724_o = n193_o;
      24'b000000000001000000000000: n724_o = n193_o;
      24'b000000000000100000000000: n724_o = 4'b0100;
      24'b000000000000010000000000: n724_o = n193_o;
      24'b000000000000001000000000: n724_o = n193_o;
      24'b000000000000000100000000: n724_o = n193_o;
      24'b000000000000000010000000: n724_o = n193_o;
      24'b000000000000000001000000: n724_o = n193_o;
      24'b000000000000000000100000: n724_o = n193_o;
      24'b000000000000000000010000: n724_o = n193_o;
      24'b000000000000000000001000: n724_o = n344_o;
      24'b000000000000000000000100: n724_o = n193_o;
      24'b000000000000000000000010: n724_o = n193_o;
      24'b000000000000000000000001: n724_o = n193_o;
      default: n724_o = n193_o;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n725_o = n201_o;
      24'b010000000000000000000000: n725_o = n201_o;
      24'b001000000000000000000000: n725_o = n201_o;
      24'b000100000000000000000000: n725_o = n201_o;
      24'b000010000000000000000000: n725_o = n201_o;
      24'b000001000000000000000000: n725_o = n201_o;
      24'b000000100000000000000000: n725_o = n201_o;
      24'b000000010000000000000000: n725_o = n201_o;
      24'b000000001000000000000000: n725_o = n201_o;
      24'b000000000100000000000000: n725_o = n201_o;
      24'b000000000010000000000000: n725_o = n201_o;
      24'b000000000001000000000000: n725_o = n201_o;
      24'b000000000000100000000000: n725_o = n201_o;
      24'b000000000000010000000000: n725_o = n201_o;
      24'b000000000000001000000000: n725_o = n201_o;
      24'b000000000000000100000000: n725_o = n201_o;
      24'b000000000000000010000000: n725_o = n201_o;
      24'b000000000000000001000000: n725_o = n201_o;
      24'b000000000000000000100000: n725_o = n201_o;
      24'b000000000000000000010000: n725_o = n201_o;
      24'b000000000000000000001000: n725_o = n254_o;
      24'b000000000000000000000100: n725_o = n201_o;
      24'b000000000000000000000010: n725_o = 1'b0;
      24'b000000000000000000000001: n725_o = n201_o;
      default: n725_o = n201_o;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n726_o = 3'b010;
      24'b010000000000000000000000: n726_o = 3'b010;
      24'b001000000000000000000000: n726_o = 3'b010;
      24'b000100000000000000000000: n726_o = 3'b011;
      24'b000010000000000000000000: n726_o = 3'b010;
      24'b000001000000000000000000: n726_o = 3'b011;
      24'b000000100000000000000000: n726_o = 3'b010;
      24'b000000010000000000000000: n726_o = 3'b010;
      24'b000000001000000000000000: n726_o = 3'b010;
      24'b000000000100000000000000: n726_o = 3'b010;
      24'b000000000010000000000000: n726_o = 3'b010;
      24'b000000000001000000000000: n726_o = 3'b010;
      24'b000000000000100000000000: n726_o = 3'b011;
      24'b000000000000010000000000: n726_o = 3'b010;
      24'b000000000000001000000000: n726_o = 3'b010;
      24'b000000000000000100000000: n726_o = 3'b010;
      24'b000000000000000010000000: n726_o = 3'b1XX;
      24'b000000000000000001000000: n726_o = 3'b1XX;
      24'b000000000000000000100000: n726_o = 3'b010;
      24'b000000000000000000010000: n726_o = n427_o;
      24'b000000000000000000001000: n726_o = 3'b000;
      24'b000000000000000000000100: n726_o = 3'b010;
      24'b000000000000000000000010: n726_o = 3'b010;
      24'b000000000000000000000001: n726_o = 3'b010;
      default: n726_o = 3'b010;
    endcase
  assign n727_o = n190_o[23];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n728_o = n727_o;
      24'b010000000000000000000000: n728_o = n727_o;
      24'b001000000000000000000000: n728_o = n727_o;
      24'b000100000000000000000000: n728_o = 1'b1;
      24'b000010000000000000000000: n728_o = n727_o;
      24'b000001000000000000000000: n728_o = 1'b1;
      24'b000000100000000000000000: n728_o = n727_o;
      24'b000000010000000000000000: n728_o = n727_o;
      24'b000000001000000000000000: n728_o = n727_o;
      24'b000000000100000000000000: n728_o = n727_o;
      24'b000000000010000000000000: n728_o = n727_o;
      24'b000000000001000000000000: n728_o = n727_o;
      24'b000000000000100000000000: n728_o = 1'b1;
      24'b000000000000010000000000: n728_o = n727_o;
      24'b000000000000001000000000: n728_o = n727_o;
      24'b000000000000000100000000: n728_o = n727_o;
      24'b000000000000000010000000: n728_o = 1'b1;
      24'b000000000000000001000000: n728_o = 1'b1;
      24'b000000000000000000100000: n728_o = n727_o;
      24'b000000000000000000010000: n728_o = n727_o;
      24'b000000000000000000001000: n728_o = n727_o;
      24'b000000000000000000000100: n728_o = n727_o;
      24'b000000000000000000000010: n728_o = n727_o;
      24'b000000000000000000000001: n728_o = n727_o;
      default: n728_o = n727_o;
    endcase
  assign n729_o = n190_o[24];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n730_o = n729_o;
      24'b010000000000000000000000: n730_o = n729_o;
      24'b001000000000000000000000: n730_o = 1'b1;
      24'b000100000000000000000000: n730_o = n729_o;
      24'b000010000000000000000000: n730_o = n729_o;
      24'b000001000000000000000000: n730_o = n729_o;
      24'b000000100000000000000000: n730_o = n729_o;
      24'b000000010000000000000000: n730_o = n729_o;
      24'b000000001000000000000000: n730_o = 1'b1;
      24'b000000000100000000000000: n730_o = 1'b1;
      24'b000000000010000000000000: n730_o = n729_o;
      24'b000000000001000000000000: n730_o = n729_o;
      24'b000000000000100000000000: n730_o = n729_o;
      24'b000000000000010000000000: n730_o = n729_o;
      24'b000000000000001000000000: n730_o = n729_o;
      24'b000000000000000100000000: n730_o = n729_o;
      24'b000000000000000010000000: n730_o = n729_o;
      24'b000000000000000001000000: n730_o = n729_o;
      24'b000000000000000000100000: n730_o = n486_o;
      24'b000000000000000000010000: n730_o = 1'b1;
      24'b000000000000000000001000: n730_o = n729_o;
      24'b000000000000000000000100: n730_o = n729_o;
      24'b000000000000000000000010: n730_o = 1'b1;
      24'b000000000000000000000001: n730_o = n729_o;
      default: n730_o = n729_o;
    endcase
  assign n731_o = n190_o[25];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n732_o = n731_o;
      24'b010000000000000000000000: n732_o = n731_o;
      24'b001000000000000000000000: n732_o = 1'b1;
      24'b000100000000000000000000: n732_o = n731_o;
      24'b000010000000000000000000: n732_o = n731_o;
      24'b000001000000000000000000: n732_o = n731_o;
      24'b000000100000000000000000: n732_o = n731_o;
      24'b000000010000000000000000: n732_o = n731_o;
      24'b000000001000000000000000: n732_o = n731_o;
      24'b000000000100000000000000: n732_o = n731_o;
      24'b000000000010000000000000: n732_o = n731_o;
      24'b000000000001000000000000: n732_o = n731_o;
      24'b000000000000100000000000: n732_o = n731_o;
      24'b000000000000010000000000: n732_o = n731_o;
      24'b000000000000001000000000: n732_o = n731_o;
      24'b000000000000000100000000: n732_o = n731_o;
      24'b000000000000000010000000: n732_o = n731_o;
      24'b000000000000000001000000: n732_o = n731_o;
      24'b000000000000000000100000: n732_o = n731_o;
      24'b000000000000000000010000: n732_o = n731_o;
      24'b000000000000000000001000: n732_o = n731_o;
      24'b000000000000000000000100: n732_o = n731_o;
      24'b000000000000000000000010: n732_o = n731_o;
      24'b000000000000000000000001: n732_o = n731_o;
      default: n732_o = n731_o;
    endcase
  assign n733_o = n190_o[26];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n734_o = n733_o;
      24'b010000000000000000000000: n734_o = n733_o;
      24'b001000000000000000000000: n734_o = n733_o;
      24'b000100000000000000000000: n734_o = 1'b1;
      24'b000010000000000000000000: n734_o = n733_o;
      24'b000001000000000000000000: n734_o = 1'b1;
      24'b000000100000000000000000: n734_o = n733_o;
      24'b000000010000000000000000: n734_o = n733_o;
      24'b000000001000000000000000: n734_o = n733_o;
      24'b000000000100000000000000: n734_o = n733_o;
      24'b000000000010000000000000: n734_o = n733_o;
      24'b000000000001000000000000: n734_o = n733_o;
      24'b000000000000100000000000: n734_o = 1'b1;
      24'b000000000000010000000000: n734_o = n733_o;
      24'b000000000000001000000000: n734_o = n733_o;
      24'b000000000000000100000000: n734_o = n733_o;
      24'b000000000000000010000000: n734_o = n541_o;
      24'b000000000000000001000000: n734_o = 1'b1;
      24'b000000000000000000100000: n734_o = n488_o;
      24'b000000000000000000010000: n734_o = n428_o;
      24'b000000000000000000001000: n734_o = n733_o;
      24'b000000000000000000000100: n734_o = n733_o;
      24'b000000000000000000000010: n734_o = n733_o;
      24'b000000000000000000000001: n734_o = n733_o;
      default: n734_o = n733_o;
    endcase
  assign n735_o = n190_o[27];
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n736_o = n735_o;
      24'b010000000000000000000000: n736_o = 1'b1;
      24'b001000000000000000000000: n736_o = n735_o;
      24'b000100000000000000000000: n736_o = 1'b1;
      24'b000010000000000000000000: n736_o = n735_o;
      24'b000001000000000000000000: n736_o = n735_o;
      24'b000000100000000000000000: n736_o = n735_o;
      24'b000000010000000000000000: n736_o = n735_o;
      24'b000000001000000000000000: n736_o = n735_o;
      24'b000000000100000000000000: n736_o = n735_o;
      24'b000000000010000000000000: n736_o = 1'b1;
      24'b000000000001000000000000: n736_o = n735_o;
      24'b000000000000100000000000: n736_o = n735_o;
      24'b000000000000010000000000: n736_o = n597_o;
      24'b000000000000001000000000: n736_o = n735_o;
      24'b000000000000000100000000: n736_o = n735_o;
      24'b000000000000000010000000: n736_o = n735_o;
      24'b000000000000000001000000: n736_o = n735_o;
      24'b000000000000000000100000: n736_o = n735_o;
      24'b000000000000000000010000: n736_o = n735_o;
      24'b000000000000000000001000: n736_o = n735_o;
      24'b000000000000000000000100: n736_o = n735_o;
      24'b000000000000000000000010: n736_o = n735_o;
      24'b000000000000000000000001: n736_o = n735_o;
      default: n736_o = n735_o;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n737_o = mem_rd_ff;
      24'b010000000000000000000000: n737_o = mem_rd_ff;
      24'b001000000000000000000000: n737_o = 1'b1;
      24'b000100000000000000000000: n737_o = mem_rd_ff;
      24'b000010000000000000000000: n737_o = mem_rd_ff;
      24'b000001000000000000000000: n737_o = mem_rd_ff;
      24'b000000100000000000000000: n737_o = mem_rd_ff;
      24'b000000010000000000000000: n737_o = mem_rd_ff;
      24'b000000001000000000000000: n737_o = 1'b1;
      24'b000000000100000000000000: n737_o = 1'b1;
      24'b000000000010000000000000: n737_o = mem_rd_ff;
      24'b000000000001000000000000: n737_o = mem_rd_ff;
      24'b000000000000100000000000: n737_o = mem_rd_ff;
      24'b000000000000010000000000: n737_o = mem_rd_ff;
      24'b000000000000001000000000: n737_o = mem_rd_ff;
      24'b000000000000000100000000: n737_o = mem_rd_ff;
      24'b000000000000000010000000: n737_o = mem_rd_ff;
      24'b000000000000000001000000: n737_o = mem_rd_ff;
      24'b000000000000000000100000: n737_o = n489_o;
      24'b000000000000000000010000: n737_o = n429_o;
      24'b000000000000000000001000: n737_o = mem_rd_ff;
      24'b000000000000000000000100: n737_o = mem_rd_ff;
      24'b000000000000000000000010: n737_o = n249_o;
      24'b000000000000000000000001: n737_o = mem_rd_ff;
      default: n737_o = mem_rd_ff;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n750_o = am;
      24'b010000000000000000000000: n750_o = am;
      24'b001000000000000000000000: n750_o = am;
      24'b000100000000000000000000: n750_o = am;
      24'b000010000000000000000000: n750_o = am;
      24'b000001000000000000000000: n750_o = am;
      24'b000000100000000000000000: n750_o = am;
      24'b000000010000000000000000: n750_o = am;
      24'b000000001000000000000000: n750_o = am;
      24'b000000000100000000000000: n750_o = am;
      24'b000000000010000000000000: n750_o = am;
      24'b000000000001000000000000: n750_o = am;
      24'b000000000000100000000000: n750_o = am;
      24'b000000000000010000000000: n750_o = am;
      24'b000000000000001000000000: n750_o = am;
      24'b000000000000000100000000: n750_o = am;
      24'b000000000000000010000000: n750_o = am;
      24'b000000000000000001000000: n750_o = am;
      24'b000000000000000000100000: n750_o = am;
      24'b000000000000000000010000: n750_o = am;
      24'b000000000000000000001000: n750_o = n346_o;
      24'b000000000000000000000100: n750_o = am;
      24'b000000000000000000000010: n750_o = am;
      24'b000000000000000000000001: n750_o = am;
      default: n750_o = am;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n753_o = 1'b0;
      24'b010000000000000000000000: n753_o = 1'b0;
      24'b001000000000000000000000: n753_o = 1'b0;
      24'b000100000000000000000000: n753_o = 1'b0;
      24'b000010000000000000000000: n753_o = 1'b0;
      24'b000001000000000000000000: n753_o = 1'b0;
      24'b000000100000000000000000: n753_o = 1'b0;
      24'b000000010000000000000000: n753_o = 1'b0;
      24'b000000001000000000000000: n753_o = 1'b0;
      24'b000000000100000000000000: n753_o = 1'b0;
      24'b000000000010000000000000: n753_o = 1'b0;
      24'b000000000001000000000000: n753_o = 1'b0;
      24'b000000000000100000000000: n753_o = 1'b0;
      24'b000000000000010000000000: n753_o = 1'b0;
      24'b000000000000001000000000: n753_o = 1'b0;
      24'b000000000000000100000000: n753_o = 1'b0;
      24'b000000000000000010000000: n753_o = n543_o;
      24'b000000000000000001000000: n753_o = 1'b1;
      24'b000000000000000000100000: n753_o = n492_o;
      24'b000000000000000000010000: n753_o = n432_o;
      24'b000000000000000000001000: n753_o = 1'b0;
      24'b000000000000000000000100: n753_o = 1'b0;
      24'b000000000000000000000010: n753_o = 1'b0;
      24'b000000000000000000000001: n753_o = 1'b0;
      default: n753_o = 1'b0;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n755_o = src;
      24'b010000000000000000000000: n755_o = src;
      24'b001000000000000000000000: n755_o = src;
      24'b000100000000000000000000: n755_o = src;
      24'b000010000000000000000000: n755_o = src;
      24'b000001000000000000000000: n755_o = src;
      24'b000000100000000000000000: n755_o = src;
      24'b000000010000000000000000: n755_o = src;
      24'b000000001000000000000000: n755_o = src;
      24'b000000000100000000000000: n755_o = src;
      24'b000000000010000000000000: n755_o = src;
      24'b000000000001000000000000: n755_o = src;
      24'b000000000000100000000000: n755_o = src;
      24'b000000000000010000000000: n755_o = src;
      24'b000000000000001000000000: n755_o = src;
      24'b000000000000000100000000: n755_o = src;
      24'b000000000000000010000000: n755_o = src;
      24'b000000000000000001000000: n755_o = src;
      24'b000000000000000000100000: n755_o = src;
      24'b000000000000000000010000: n755_o = src;
      24'b000000000000000000001000: n755_o = n347_o;
      24'b000000000000000000000100: n755_o = src;
      24'b000000000000000000000010: n755_o = src;
      24'b000000000000000000000001: n755_o = src;
      default: n755_o = src;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n757_o = sam;
      24'b010000000000000000000000: n757_o = sam;
      24'b001000000000000000000000: n757_o = sam;
      24'b000100000000000000000000: n757_o = sam;
      24'b000010000000000000000000: n757_o = sam;
      24'b000001000000000000000000: n757_o = sam;
      24'b000000100000000000000000: n757_o = sam;
      24'b000000010000000000000000: n757_o = sam;
      24'b000000001000000000000000: n757_o = sam;
      24'b000000000100000000000000: n757_o = sam;
      24'b000000000010000000000000: n757_o = sam;
      24'b000000000001000000000000: n757_o = sam;
      24'b000000000000100000000000: n757_o = sam;
      24'b000000000000010000000000: n757_o = sam;
      24'b000000000000001000000000: n757_o = sam;
      24'b000000000000000100000000: n757_o = sam;
      24'b000000000000000010000000: n757_o = sam;
      24'b000000000000000001000000: n757_o = sam;
      24'b000000000000000000100000: n757_o = sam;
      24'b000000000000000000010000: n757_o = sam;
      24'b000000000000000000001000: n757_o = n255_o;
      24'b000000000000000000000100: n757_o = sam;
      24'b000000000000000000000010: n757_o = 2'b00;
      24'b000000000000000000000001: n757_o = sam;
      default: n757_o = sam;
    endcase
  /* core/neo430_control.vhd:201:5  */
  always @*
    case (n678_o)
      24'b100000000000000000000000: n760_o = 1'b0;
      24'b010000000000000000000000: n760_o = 1'b0;
      24'b001000000000000000000000: n760_o = 1'b1;
      24'b000100000000000000000000: n760_o = 1'b0;
      24'b000010000000000000000000: n760_o = 1'b0;
      24'b000001000000000000000000: n760_o = 1'b0;
      24'b000000100000000000000000: n760_o = 1'b0;
      24'b000000010000000000000000: n760_o = 1'b0;
      24'b000000001000000000000000: n760_o = 1'b0;
      24'b000000000100000000000000: n760_o = 1'b0;
      24'b000000000010000000000000: n760_o = 1'b0;
      24'b000000000001000000000000: n760_o = 1'b0;
      24'b000000000000100000000000: n760_o = 1'b0;
      24'b000000000000010000000000: n760_o = 1'b0;
      24'b000000000000001000000000: n760_o = 1'b0;
      24'b000000000000000100000000: n760_o = 1'b0;
      24'b000000000000000010000000: n760_o = 1'b0;
      24'b000000000000000001000000: n760_o = 1'b0;
      24'b000000000000000000100000: n760_o = 1'b0;
      24'b000000000000000000010000: n760_o = 1'b0;
      24'b000000000000000000001000: n760_o = 1'b0;
      24'b000000000000000000000100: n760_o = 1'b0;
      24'b000000000000000000000010: n760_o = 1'b0;
      24'b000000000000000000000001: n760_o = 1'b0;
      default: n760_o = 1'b0;
    endcase
  /* core/neo430_control.vhd:671:27  */
  assign n765_o = sreg_i[3];
  /* core/neo430_control.vhd:675:31  */
  assign n766_o = irq_buf[0];
  /* core/neo430_control.vhd:675:43  */
  assign n767_o = irq_i[0];
  /* core/neo430_control.vhd:675:35  */
  assign n768_o = n766_o | n767_o;
  /* core/neo430_control.vhd:675:63  */
  assign n769_o = sreg_i[14];
  /* core/neo430_control.vhd:675:53  */
  assign n770_o = ~n769_o;
  /* core/neo430_control.vhd:675:48  */
  assign n771_o = n768_o & n770_o;
  /* core/neo430_control.vhd:675:96  */
  assign n772_o = irq_ack_mask[0];
  /* core/neo430_control.vhd:675:80  */
  assign n773_o = ~n772_o;
  /* core/neo430_control.vhd:675:75  */
  assign n774_o = n771_o & n773_o;
  /* core/neo430_control.vhd:675:31  */
  assign n775_o = irq_buf[1];
  /* core/neo430_control.vhd:675:43  */
  assign n776_o = irq_i[1];
  /* core/neo430_control.vhd:675:35  */
  assign n777_o = n775_o | n776_o;
  /* core/neo430_control.vhd:675:63  */
  assign n778_o = sreg_i[14];
  /* core/neo430_control.vhd:675:53  */
  assign n779_o = ~n778_o;
  /* core/neo430_control.vhd:675:48  */
  assign n780_o = n777_o & n779_o;
  /* core/neo430_control.vhd:675:96  */
  assign n781_o = irq_ack_mask[1];
  /* core/neo430_control.vhd:675:80  */
  assign n782_o = ~n781_o;
  /* core/neo430_control.vhd:675:75  */
  assign n783_o = n780_o & n782_o;
  /* core/neo430_control.vhd:675:31  */
  assign n784_o = irq_buf[2];
  /* core/neo430_control.vhd:675:43  */
  assign n785_o = irq_i[2];
  /* core/neo430_control.vhd:675:35  */
  assign n786_o = n784_o | n785_o;
  /* core/neo430_control.vhd:675:63  */
  assign n787_o = sreg_i[14];
  /* core/neo430_control.vhd:675:53  */
  assign n788_o = ~n787_o;
  /* core/neo430_control.vhd:675:48  */
  assign n789_o = n786_o & n788_o;
  /* core/neo430_control.vhd:675:96  */
  assign n790_o = irq_ack_mask[2];
  /* core/neo430_control.vhd:675:80  */
  assign n791_o = ~n790_o;
  /* core/neo430_control.vhd:675:75  */
  assign n792_o = n789_o & n791_o;
  /* core/neo430_control.vhd:675:31  */
  assign n793_o = irq_buf[3];
  /* core/neo430_control.vhd:675:43  */
  assign n794_o = irq_i[3];
  /* core/neo430_control.vhd:675:35  */
  assign n795_o = n793_o | n794_o;
  /* core/neo430_control.vhd:675:63  */
  assign n796_o = sreg_i[14];
  /* core/neo430_control.vhd:675:53  */
  assign n797_o = ~n796_o;
  /* core/neo430_control.vhd:675:48  */
  assign n798_o = n795_o & n797_o;
  /* core/neo430_control.vhd:675:96  */
  assign n799_o = irq_ack_mask[3];
  /* core/neo430_control.vhd:675:80  */
  assign n800_o = ~n799_o;
  /* core/neo430_control.vhd:675:75  */
  assign n801_o = n798_o & n800_o;
  /* core/neo430_control.vhd:678:21  */
  assign n802_o = ~irq_start;
  /* core/neo430_control.vhd:678:38  */
  assign n803_o = sreg_i[3];
  /* core/neo430_control.vhd:678:49  */
  assign n804_o = ~n803_o;
  /* core/neo430_control.vhd:678:28  */
  assign n805_o = n802_o | n804_o;
  /* core/neo430_control.vhd:680:9  */
  assign n808_o = irq_fire ? 1'b1 : 1'b0;
  /* core/neo430_control.vhd:685:9  */
  assign n812_o = irq_ack ? 1'b0 : irq_start;
  /* core/neo430_control.vhd:678:7  */
  assign n813_o = n805_o ? n808_o : n812_o;
  /* core/neo430_control.vhd:678:7  */
  assign n814_o = irq_fire & n805_o;
  assign n816_o = {n801_o, n792_o, n783_o, n774_o};
  /* core/neo430_control.vhd:693:33  */
  assign n824_o = irq_buf != 4'b0000;
  /* core/neo430_control.vhd:693:44  */
  assign n825_o = i_flag_ff1 & n824_o;
  /* core/neo430_control.vhd:693:78  */
  assign n826_o = sreg_i[3];
  /* core/neo430_control.vhd:693:67  */
  assign n827_o = n826_o & n825_o;
  /* core/neo430_control.vhd:693:19  */
  assign n828_o = n827_o ? 1'b1 : 1'b0;
  /* core/neo430_control.vhd:699:26  */
  assign n832_o = {irq_ack, irq_vec};
  /* core/neo430_control.vhd:701:7  */
  assign n834_o = n832_o == 3'b100;
  /* core/neo430_control.vhd:702:7  */
  assign n836_o = n832_o == 3'b101;
  /* core/neo430_control.vhd:703:7  */
  assign n838_o = n832_o == 3'b110;
  /* core/neo430_control.vhd:704:7  */
  assign n840_o = n832_o == 3'b111;
  assign n841_o = {n840_o, n838_o, n836_o, n834_o};
  /* core/neo430_control.vhd:700:5  */
  always @*
    case (n841_o)
      4'b1000: n847_o = 4'b1000;
      4'b0100: n847_o = 4'b0100;
      4'b0010: n847_o = 4'b0010;
      4'b0001: n847_o = 4'b0001;
      default: n847_o = 4'b0000;
    endcase
  /* core/neo430_control.vhd:714:7  */
  assign n851_o = irq_buf == 4'b0001;
  /* core/neo430_control.vhd:714:19  */
  assign n853_o = irq_buf == 4'b0011;
  /* core/neo430_control.vhd:714:19  */
  assign n854_o = n851_o | n853_o;
  /* core/neo430_control.vhd:714:28  */
  assign n856_o = irq_buf == 4'b0101;
  /* core/neo430_control.vhd:714:28  */
  assign n857_o = n854_o | n856_o;
  /* core/neo430_control.vhd:714:37  */
  assign n859_o = irq_buf == 4'b0111;
  /* core/neo430_control.vhd:714:37  */
  assign n860_o = n857_o | n859_o;
  /* core/neo430_control.vhd:714:46  */
  assign n862_o = irq_buf == 4'b1001;
  /* core/neo430_control.vhd:714:46  */
  assign n863_o = n860_o | n862_o;
  /* core/neo430_control.vhd:714:55  */
  assign n865_o = irq_buf == 4'b1011;
  /* core/neo430_control.vhd:714:55  */
  assign n866_o = n863_o | n865_o;
  /* core/neo430_control.vhd:714:64  */
  assign n868_o = irq_buf == 4'b1101;
  /* core/neo430_control.vhd:714:64  */
  assign n869_o = n866_o | n868_o;
  /* core/neo430_control.vhd:714:73  */
  assign n871_o = irq_buf == 4'b1111;
  /* core/neo430_control.vhd:714:73  */
  assign n872_o = n869_o | n871_o;
  /* core/neo430_control.vhd:716:7  */
  assign n874_o = irq_buf == 4'b0010;
  /* core/neo430_control.vhd:716:19  */
  assign n876_o = irq_buf == 4'b0110;
  /* core/neo430_control.vhd:716:19  */
  assign n877_o = n874_o | n876_o;
  /* core/neo430_control.vhd:716:28  */
  assign n879_o = irq_buf == 4'b1010;
  /* core/neo430_control.vhd:716:28  */
  assign n880_o = n877_o | n879_o;
  /* core/neo430_control.vhd:716:37  */
  assign n882_o = irq_buf == 4'b1110;
  /* core/neo430_control.vhd:716:37  */
  assign n883_o = n880_o | n882_o;
  /* core/neo430_control.vhd:718:7  */
  assign n885_o = irq_buf == 4'b0100;
  /* core/neo430_control.vhd:718:19  */
  assign n887_o = irq_buf == 4'b1100;
  /* core/neo430_control.vhd:718:19  */
  assign n888_o = n885_o | n887_o;
  assign n889_o = {n888_o, n883_o, n872_o};
  /* core/neo430_control.vhd:713:5  */
  always @*
    case (n889_o)
      3'b100: n894_o = 2'b10;
      3'b010: n894_o = 2'b01;
      3'b001: n894_o = 2'b00;
      default: n894_o = 2'b11;
    endcase
  /* core/neo430_control.vhd:127:5  */
  assign n896_o = ir_wren ? instr_i : ir;
  /* core/neo430_control.vhd:127:5  */
  always @(posedge clk_i)
    n897_q <= n896_o;
  /* core/neo430_control.vhd:120:5  */
  always @(posedge clk_i or posedge n156_o)
    if (n156_o)
      n898_q <= 5'b00000;
    else
      n898_q <= state_nxt;
  /* core/neo430_control.vhd:118:5  */
  assign n899_o = {n737_o, n736_o, n734_o, n732_o, n730_o, n728_o, n726_o, n725_o, n724_o, n723_o, n721_o, n719_o, n717_o, n715_o, n713_o, n711_o, n709_o, n707_o, n705_o, n703_o, n702_o};
  /* core/neo430_control.vhd:127:5  */
  always @(posedge clk_i)
    n900_q <= ctrl_nxt;
  /* core/neo430_control.vhd:127:5  */
  always @(posedge clk_i)
    n901_q <= am_nxt;
  /* core/neo430_control.vhd:127:5  */
  always @(posedge clk_i)
    n902_q <= mem_rd;
  /* core/neo430_control.vhd:127:5  */
  always @(posedge clk_i)
    n903_q <= src_nxt;
  /* core/neo430_control.vhd:127:5  */
  always @(posedge clk_i)
    n904_q <= sam_nxt;
  /* core/neo430_control.vhd:668:5  */
  always @(posedge clk_i)
    n905_q <= n813_o;
  /* core/neo430_control.vhd:668:5  */
  always @(posedge clk_i)
    n906_q <= n816_o;
  /* core/neo430_control.vhd:668:5  */
  assign n907_o = n814_o ? irq_vec_nxt : irq_vec;
  /* core/neo430_control.vhd:668:5  */
  always @(posedge clk_i)
    n908_q <= n907_o;
  /* core/neo430_control.vhd:668:5  */
  always @(posedge clk_i)
    n909_q <= n765_o;
  /* core/neo430_control.vhd:668:5  */
  always @(posedge clk_i)
    n910_q <= i_flag_ff0;
endmodule

module neo430_cpu_3f29546453678b855931c174a97d6c0894b8f546
  (input  clk_i,
   input  rst_i,
   input  [15:0] mem_data_i,
   input  [3:0] irq_i,
   output mem_rd_o,
   output mem_imwe_o,
   output [1:0] mem_wr_o,
   output [15:0] mem_addr_o,
   output [15:0] mem_data_o);
  wire [15:0] mem_addr;
  wire [15:0] mdi;
  wire [15:0] mdi_gate;
  wire [15:0] mdo_gate;
  wire [28:0] ctrl_bus;
  wire [15:0] sreg;
  wire [4:0] alu_flags;
  wire [15:0] imm;
  wire [15:0] rf_read;
  wire [15:0] alu_res;
  wire [15:0] addr_fb;
  wire [1:0] irq_sel;
  wire dio_swap;
  wire bw_ff;
  wire [28:0] neo430_control_inst_n25;
  wire [1:0] neo430_control_inst_n26;
  wire [15:0] neo430_control_inst_n27;
  wire [28:0] neo430_control_inst_ctrl_o;
  wire [1:0] neo430_control_inst_irq_vec_o;
  wire [15:0] neo430_control_inst_imm_o;
  wire [15:0] neo430_reg_file_inst_n34;
  wire [15:0] neo430_reg_file_inst_n35;
  wire [15:0] neo430_reg_file_inst_data_o;
  wire [15:0] neo430_reg_file_inst_sreg_o;
  wire [15:0] neo430_alu_inst_n40;
  wire [4:0] neo430_alu_inst_n41;
  wire [15:0] neo430_alu_inst_data_o;
  wire [4:0] neo430_alu_inst_flag_o;
  wire [15:0] neo430_addr_gen_inst_n46;
  wire [15:0] neo430_addr_gen_inst_n47;
  wire [15:0] neo430_addr_gen_inst_mem_addr_o;
  wire [15:0] neo430_addr_gen_inst_dwb_o;
  wire n54_o;
  wire n55_o;
  wire n56_o;
  wire n57_o;
  wire n63_o;
  wire n64_o;
  wire n65_o;
  wire n66_o;
  wire n67_o;
  wire n68_o;
  wire n69_o;
  wire n70_o;
  wire n71_o;
  wire n72_o;
  wire n73_o;
  wire n74_o;
  wire n75_o;
  wire n76_o;
  wire n77_o;
  wire [15:0] n79_o;
  wire n81_o;
  wire [15:0] n82_o;
  wire [7:0] n83_o;
  wire [7:0] n84_o;
  wire [15:0] n85_o;
  wire n86_o;
  wire [15:0] n87_o;
  wire [7:0] n88_o;
  wire [7:0] n89_o;
  wire [15:0] n90_o;
  wire [15:0] n93_o;
  wire [14:0] n95_o;
  wire [15:0] n97_o;
  reg n98_q;
  reg n99_q;
  wire [1:0] n101_o;
  assign mem_rd_o = n63_o;
  assign mem_imwe_o = n77_o;
  assign mem_wr_o = n101_o;
  assign mem_addr_o = n97_o;
  assign mem_data_o = n93_o;
  /* core/neo430_cpu.vhd:68:10  */
  assign mem_addr = neo430_addr_gen_inst_n46; // (signal)
  /* core/neo430_cpu.vhd:69:10  */
  assign mdi = n82_o; // (signal)
  /* core/neo430_cpu.vhd:70:10  */
  assign mdi_gate = n79_o; // (signal)
  /* core/neo430_cpu.vhd:71:10  */
  assign mdo_gate = n87_o; // (signal)
  /* core/neo430_cpu.vhd:72:10  */
  assign ctrl_bus = neo430_control_inst_n25; // (signal)
  /* core/neo430_cpu.vhd:73:10  */
  assign sreg = neo430_reg_file_inst_n35; // (signal)
  /* core/neo430_cpu.vhd:74:10  */
  assign alu_flags = neo430_alu_inst_n41; // (signal)
  /* core/neo430_cpu.vhd:75:10  */
  assign imm = neo430_control_inst_n27; // (signal)
  /* core/neo430_cpu.vhd:76:10  */
  assign rf_read = neo430_reg_file_inst_n34; // (signal)
  /* core/neo430_cpu.vhd:77:10  */
  assign alu_res = neo430_alu_inst_n40; // (signal)
  /* core/neo430_cpu.vhd:78:10  */
  assign addr_fb = neo430_addr_gen_inst_n47; // (signal)
  /* core/neo430_cpu.vhd:79:10  */
  assign irq_sel = neo430_control_inst_n26; // (signal)
  /* core/neo430_cpu.vhd:80:10  */
  assign dio_swap = n98_q; // (signal)
  /* core/neo430_cpu.vhd:81:10  */
  assign bw_ff = n99_q; // (signal)
  /* core/neo430_cpu.vhd:97:19  */
  assign neo430_control_inst_n25 = neo430_control_inst_ctrl_o; // (signal)
  /* core/neo430_cpu.vhd:98:19  */
  assign neo430_control_inst_n26 = neo430_control_inst_irq_vec_o; // (signal)
  /* core/neo430_cpu.vhd:99:19  */
  assign neo430_control_inst_n27 = neo430_control_inst_imm_o; // (signal)
  /* core/neo430_cpu.vhd:88:3  */
  neo430_control neo430_control_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .instr_i(mem_data_i),
    .sreg_i(sreg),
    .irq_i(irq_i),
    .ctrl_o(neo430_control_inst_ctrl_o),
    .irq_vec_o(neo430_control_inst_irq_vec_o),
    .imm_o(neo430_control_inst_imm_o));
  /* core/neo430_cpu.vhd:123:19  */
  assign neo430_reg_file_inst_n34 = neo430_reg_file_inst_data_o; // (signal)
  /* core/neo430_cpu.vhd:124:19  */
  assign neo430_reg_file_inst_n35 = neo430_reg_file_inst_sreg_o; // (signal)
  /* core/neo430_cpu.vhd:107:3  */
  neo430_reg_file_3f29546453678b855931c174a97d6c0894b8f546 neo430_reg_file_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .alu_i(alu_res),
    .addr_i(addr_fb),
    .flag_i(alu_flags),
    .ctrl_i(ctrl_bus),
    .data_o(neo430_reg_file_inst_data_o),
    .sreg_o(neo430_reg_file_inst_sreg_o));
  /* core/neo430_cpu.vhd:141:19  */
  assign neo430_alu_inst_n40 = neo430_alu_inst_data_o; // (signal)
  /* core/neo430_cpu.vhd:142:19  */
  assign neo430_alu_inst_n41 = neo430_alu_inst_flag_o; // (signal)
  /* core/neo430_cpu.vhd:130:3  */
  neo430_alu neo430_alu_inst (
    .clk_i(clk_i),
    .reg_i(rf_read),
    .mem_i(mdi),
    .sreg_i(sreg),
    .ctrl_i(ctrl_bus),
    .data_o(neo430_alu_inst_data_o),
    .flag_o(neo430_alu_inst_flag_o));
  /* core/neo430_cpu.vhd:160:19  */
  assign neo430_addr_gen_inst_n46 = neo430_addr_gen_inst_mem_addr_o; // (signal)
  /* core/neo430_cpu.vhd:161:19  */
  assign neo430_addr_gen_inst_n47 = neo430_addr_gen_inst_dwb_o; // (signal)
  /* core/neo430_cpu.vhd:148:3  */
  neo430_addr_gen neo430_addr_gen_inst (
    .clk_i(clk_i),
    .reg_i(rf_read),
    .mem_i(mdi),
    .imm_i(imm),
    .irq_sel_i(irq_sel),
    .ctrl_i(ctrl_bus),
    .mem_addr_o(neo430_addr_gen_inst_mem_addr_o),
    .dwb_o(neo430_addr_gen_inst_dwb_o));
  /* core/neo430_cpu.vhd:170:27  */
  assign n54_o = ctrl_bus[19];
  /* core/neo430_cpu.vhd:171:27  */
  assign n55_o = ctrl_bus[19];
  /* core/neo430_cpu.vhd:171:55  */
  assign n56_o = mem_addr[0];
  /* core/neo430_cpu.vhd:171:43  */
  assign n57_o = n55_o & n56_o;
  /* core/neo430_cpu.vhd:177:23  */
  assign n63_o = ctrl_bus[28];
  /* core/neo430_cpu.vhd:180:26  */
  assign n64_o = ctrl_bus[27];
  /* core/neo430_cpu.vhd:180:54  */
  assign n65_o = ~bw_ff;
  /* core/neo430_cpu.vhd:180:42  */
  assign n66_o = n65_o ? n64_o : n70_o;
  /* core/neo430_cpu.vhd:180:75  */
  assign n67_o = ctrl_bus[27];
  /* core/neo430_cpu.vhd:180:108  */
  assign n68_o = mem_addr[0];
  /* core/neo430_cpu.vhd:180:96  */
  assign n69_o = ~n68_o;
  /* core/neo430_cpu.vhd:180:91  */
  assign n70_o = n67_o & n69_o;
  /* core/neo430_cpu.vhd:181:26  */
  assign n71_o = ctrl_bus[27];
  /* core/neo430_cpu.vhd:181:54  */
  assign n72_o = ~bw_ff;
  /* core/neo430_cpu.vhd:181:42  */
  assign n73_o = n72_o ? n71_o : n76_o;
  /* core/neo430_cpu.vhd:181:75  */
  assign n74_o = ctrl_bus[27];
  /* core/neo430_cpu.vhd:181:108  */
  assign n75_o = mem_addr[0];
  /* core/neo430_cpu.vhd:181:91  */
  assign n76_o = n74_o & n75_o;
  /* core/neo430_cpu.vhd:184:21  */
  assign n77_o = sreg[15];
  /* core/neo430_cpu.vhd:187:28  */
  assign n79_o = 1'b1 ? mem_data_i : 16'b0000000000000000;
  /* core/neo430_cpu.vhd:188:43  */
  assign n81_o = ~dio_swap;
  /* core/neo430_cpu.vhd:188:28  */
  assign n82_o = n81_o ? mdi_gate : n85_o;
  /* core/neo430_cpu.vhd:188:63  */
  assign n83_o = mdi_gate[7:0];
  /* core/neo430_cpu.vhd:188:86  */
  assign n84_o = mdi_gate[15:8];
  /* core/neo430_cpu.vhd:188:76  */
  assign n85_o = {n83_o, n84_o};
  /* core/neo430_cpu.vhd:189:43  */
  assign n86_o = ~dio_swap;
  /* core/neo430_cpu.vhd:189:28  */
  assign n87_o = n86_o ? alu_res : n90_o;
  /* core/neo430_cpu.vhd:189:62  */
  assign n88_o = alu_res[7:0];
  /* core/neo430_cpu.vhd:189:84  */
  assign n89_o = alu_res[15:8];
  /* core/neo430_cpu.vhd:189:75  */
  assign n90_o = {n88_o, n89_o};
  /* core/neo430_cpu.vhd:190:28  */
  assign n93_o = 1'b1 ? mdo_gate : 16'b0000000000000000;
  /* core/neo430_cpu.vhd:193:25  */
  assign n95_o = mem_addr[15:1];
  /* core/neo430_cpu.vhd:193:39  */
  assign n97_o = {n95_o, 1'b0};
  /* core/neo430_cpu.vhd:169:5  */
  always @(posedge clk_i)
    n98_q <= n57_o;
  /* core/neo430_cpu.vhd:169:5  */
  always @(posedge clk_i)
    n99_q <= n54_o;
  /* core/neo430_cpu.vhd:169:5  */
  assign n101_o = {n73_o, n66_o};
endmodule

module neo430_cpu_std_logic
  (input  clk_i,
   input  rst_i,
   input  [15:0] mem_data_i,
   input  [3:0] irq_i,
   output mem_rd_o,
   output mem_imwe_o,
   output [1:0] mem_wr_o,
   output [15:0] mem_addr_o,
   output [15:0] mem_data_o);
  wire clk_i_int;
  wire rst_i_int;
  wire mem_rd_o_int;
  wire mem_imwe_o_int;
  wire [1:0] mem_wr_o_int;
  wire [15:0] mem_addr_o_int;
  wire [15:0] mem_data_o_int;
  wire [15:0] mem_data_i_int;
  wire [3:0] irq_i_int;
  wire neo430_cpu_inst_n5;
  wire neo430_cpu_inst_n6;
  wire [1:0] neo430_cpu_inst_n7;
  wire [15:0] neo430_cpu_inst_n8;
  wire [15:0] neo430_cpu_inst_n9;
  wire neo430_cpu_inst_mem_rd_o;
  wire neo430_cpu_inst_mem_imwe_o;
  wire [1:0] neo430_cpu_inst_mem_wr_o;
  wire [15:0] neo430_cpu_inst_mem_addr_o;
  wire [15:0] neo430_cpu_inst_mem_data_o;
  assign mem_rd_o = mem_rd_o_int;
  assign mem_imwe_o = mem_imwe_o_int;
  assign mem_wr_o = mem_wr_o_int;
  assign mem_addr_o = mem_addr_o_int;
  assign mem_data_o = mem_data_o_int;
  /* neo430_cpu_std_logic.vhd:69:12  */
  assign clk_i_int = clk_i; // (signal)
  /* neo430_cpu_std_logic.vhd:70:12  */
  assign rst_i_int = rst_i; // (signal)
  /* neo430_cpu_std_logic.vhd:72:12  */
  assign mem_rd_o_int = neo430_cpu_inst_n5; // (signal)
  /* neo430_cpu_std_logic.vhd:73:12  */
  assign mem_imwe_o_int = neo430_cpu_inst_n6; // (signal)
  /* neo430_cpu_std_logic.vhd:74:12  */
  assign mem_wr_o_int = neo430_cpu_inst_n7; // (signal)
  /* neo430_cpu_std_logic.vhd:75:12  */
  assign mem_addr_o_int = neo430_cpu_inst_n8; // (signal)
  /* neo430_cpu_std_logic.vhd:76:12  */
  assign mem_data_o_int = neo430_cpu_inst_n9; // (signal)
  /* neo430_cpu_std_logic.vhd:77:12  */
  assign mem_data_i_int = mem_data_i; // (signal)
  /* neo430_cpu_std_logic.vhd:79:12  */
  assign irq_i_int = irq_i; // (signal)
  /* neo430_cpu_std_logic.vhd:96:19  */
  assign neo430_cpu_inst_n5 = neo430_cpu_inst_mem_rd_o; // (signal)
  /* neo430_cpu_std_logic.vhd:97:19  */
  assign neo430_cpu_inst_n6 = neo430_cpu_inst_mem_imwe_o; // (signal)
  /* neo430_cpu_std_logic.vhd:98:19  */
  assign neo430_cpu_inst_n7 = neo430_cpu_inst_mem_wr_o; // (signal)
  /* neo430_cpu_std_logic.vhd:99:19  */
  assign neo430_cpu_inst_n8 = neo430_cpu_inst_mem_addr_o; // (signal)
  /* neo430_cpu_std_logic.vhd:100:19  */
  assign neo430_cpu_inst_n9 = neo430_cpu_inst_mem_data_o; // (signal)
  /* neo430_cpu_std_logic.vhd:85:3  */
  neo430_cpu_3f29546453678b855931c174a97d6c0894b8f546 neo430_cpu_inst (
    .clk_i(clk_i_int),
    .rst_i(rst_i_int),
    .mem_data_i(mem_data_i_int),
    .irq_i(irq_i_int),
    .mem_rd_o(neo430_cpu_inst_mem_rd_o),
    .mem_imwe_o(neo430_cpu_inst_mem_imwe_o),
    .mem_wr_o(neo430_cpu_inst_mem_wr_o),
    .mem_addr_o(neo430_cpu_inst_mem_addr_o),
    .mem_data_o(neo430_cpu_inst_mem_data_o));
endmodule

