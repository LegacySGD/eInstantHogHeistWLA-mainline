<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var scenarioPrizes = getPrizesData(scenario);
						var scenarioMainGame = getMainGameData(scenario);
						var scenarioBonusGame = getBonusGameData(scenario);
						//var convertedPrizeValues = (prizeValues.substring(1)).split('|');
						var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function(item) {return item.replace(/\t|\r|\n/gm, "")} );
						var prizeNames = (prizeNamesDesc.substring(1)).split(','); 

						////////////////////
						// Parse scenario //
						////////////////////
						const symbolQty   = 10;
						const rowQty      = 6;
						const columnQty   = 5;

						var bonusTriggerCount = 0;
						var doBonusGame = false;

						// Configure line play storage to calculate winners
						var arrSymbolCounts = new Array(rowQty);       // create an empty array of length rowQty
						for (var i = 0; i < rowQty; i++) 
						{
  							arrSymbolCounts[i] = new Array(symbolQty); // make each element an array of symbolQty
							for (var j = 0; j < symbolQty; j++)
							{
								arrSymbolCounts[i][j] = 0;             // Set all to 0 as otherwise undefined
							}
						}

						for (var rowIndex = 0; rowIndex < rowQty; rowIndex++)
						{
							for (var columnIndex = 0; columnIndex < columnQty; columnIndex++)
							{	
								symbolCounter = columnIndex + (rowIndex*5);

								if (scenarioMainGame[rowIndex][columnIndex] == 'X')      // X is Bonus Trigger
								{
									bonusTriggerCount++;
								}
								else if (scenarioMainGame[rowIndex][columnIndex] == 'W') // Wild so add 1 to all on this line
								{
									for (var i = 0; i < symbolQty; i++)
									{
										arrSymbolCounts[rowIndex][i]++;
									}
								}
								else // Add 1 to this symbol on this row
								{
									arrSymbolCounts[rowIndex][scenarioMainGame[rowIndex][columnIndex].charCodeAt(0) - 65]++;
								}
							}
						}
						if (bonusTriggerCount > 4) // check Bonus Trigger count
						{
							doBonusGame = true;
						}

						var r = [];
						////////////////////
						//  Testing Only  //
						////////////////////
					//	r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
					//	for (var rowIndex = 0; rowIndex < rowQty; rowIndex++)
					//	{
					//		var rowInfo = '';
					//		r.push('<tr class="tablehead">');
					//		for (var i = 0; i < symbolQty; i++)
					//		{
					//			rowInfo = rowInfo + arrSymbolCounts[rowIndex][i].toString() + ', ';
					//		}
					//		r.push('<td>' + rowInfo + '</td>');
					//		r.push('</tr>');
					//	}
					//	r.push('</table>');
						////////////////////
						//  Testing Only  //
						////////////////////

						///////////////////////
						// Output Game Parts //
						///////////////////////

						const symbEvents = 'ABCDEFGHIJ';
						const symbIWs    = 'vwxyz';
						const doRotate   = true;
						const doTitle    = true;

						const cellHeight    = 24;
						const cellWidth     = 96;
						const cellWidthKey  = 24;
						const cellMargin    = 1;
						const cellTextY     = 15;
						const cellBonusHeight = 72;
						const colourBlack   = '#000000';
						const colourBlue    = '#99ccff';
						const colourBrown   = '#964b00';
						const colourCyan	= '#99ffff';
						const colourGreen   = '#006400';
						const colourLemon   = '#ffff99';
						const colourLilac   = '#ccccff';
						const colourLime    = '#ccff99';
						const colourOrange  = '#ffcc99';
						const colourPink    = '#ffc0cb';
						const colourPurple  = '#cc99ff';
						const colourRed     = '#ff9999';
						const colourWhite   = '#ffffff';
						const colourMidGreen = '#7fff99';

						const prizeColours  = [colourRed, colourOrange, colourLemon, colourLime, colourMidGreen, colourCyan, colourBlue, colourLilac, colourPurple, colourPink];
						const symbWild 		= 'W';				
						const symbBonus 	= 'X';
						const symbSpecials   = symbWild + symbBonus;
						const specialBoxColours  = [colourBrown, colourGreen];
						const specialTextColours = [colourWhite, colourWhite];

						var boxColourStr  = '';
						var textColourStr = '';
						var canvasIdStr   = '';
						var elementStr    = '';
						var symbEvent     = '';
						var symbIW        = '';

						function showSymb(A_strCanvasId, A_strCanvasElement, A_iBoxWidth, A_strBoxColour, A_strTextColour, A_strText, A_doRotate, A_doTitle)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var canvasWidth  = (A_doRotate) ? cellHeight + 2 * cellMargin : A_iBoxWidth + 2 * cellMargin;
							var canvasHeight = (A_doRotate) ? A_iBoxWidth + 2 * cellMargin : cellHeight + 2 * cellMargin;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							if (A_doRotate)
							{
								r.push(canvasCtxStr + '.translate(0,' + (A_iBoxWidth + 3).toString() + ');');
								r.push(canvasCtxStr + '.rotate(-Math.PI / 2);');
							}

							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + A_iBoxWidth.toString() + ', ' + cellHeight.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (A_iBoxWidth - 2).toString() + ', ' + (cellHeight - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (A_iBoxWidth / 2 + cellMargin).toString() + ', ' + cellTextY.toString() + ');');

							r.push('</script>');
						}

						////////////////
						// Symbol Key //
						////////////////
						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titleSymbolKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						for (var loopIndex = 1; loopIndex < 3; loopIndex++)
						{
							r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
							r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						}
						r.push('</tr>');

						var symbIndex = 0;
						for (var eventIndex = 0; eventIndex < 5; eventIndex++)
						{
							r.push('<tr class="tablebody">');
							for (var innerPrizeIndex = 1; innerPrizeIndex < 3; innerPrizeIndex++)
							{
								symbIndex    = eventIndex + ((innerPrizeIndex -1)*5);
								symbEvent    = symbEvents[symbIndex];
								canvasIdStr  = 'cvsKeySymb' + symbEvent;
								elementStr   = 'eleKeySymb' + symbEvent;
								boxColourStr = prizeColours[symbIndex]; 
								textColourStr = colourBlack; 
								symbDesc     = 'symb' + symbEvent.toUpperCase();
								r.push('<td align="center">');
								showSymb(canvasIdStr, elementStr, cellWidthKey, boxColourStr, textColourStr, symbEvent, !doRotate, !doTitle);
								r.push('</td>');
								r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							}
							r.push('</tr>');
						}
						r.push('</table>');
						r.push('</div>');

						////////////////////////
						// Action Symbols Key //
						////////////////////////
						var specIndex = 0;
						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titleActionSymbolsKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var specialIndex = 0; specialIndex < symbSpecials.length; specialIndex++)
						{
							r.push('<tr class="tablebody">');
							specIndex	  = specialIndex; // + innerPrizeIndex;
							symbSpecial   = symbSpecials[specIndex];
							canvasIdStr   = 'cvsKeySpecialSymb' + symbSpecial;
							elementStr    = 'keySpecialSymb' + symbSpecial;
							boxColourStr  = specialBoxColours[specIndex];
							textColourStr = specialTextColours[specIndex];
							symbDesc      = 'symb' + symbSpecial;

							r.push('<td align="center">');
							showSymb(canvasIdStr, elementStr, cellWidthKey, boxColourStr, textColourStr, symbSpecial, !doRotate, !doTitle);
							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						///////////////
						// Main Game //
						///////////////
						var cellStr    = '';
						var prizeText  = '';

						r.push('<p style="clear:both"><br>' + getTranslationByName("mainGame", translations) + '</p>');
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						///////////////////////
						// Main Game Symbols //
						///////////////////////
						var symbolCounter = 0;
						var symbIndex = 0;
						var isSpecialCell = false;

						for (var rowIndex = 0; rowIndex < rowQty; rowIndex++)
						{
							r.push('<tr class="tablebody">');
							for (var columnIndex = 0; columnIndex < columnQty; columnIndex++)
							{	
								symbolCounter = columnIndex + (rowIndex*5);
								symbCell	  = scenarioMainGame[rowIndex][columnIndex];
								canvasIdStr   = 'cvsTitleMain' + symbolCounter.toString();
								elementStr    = 'eleTitleMain' + symbolCounter.toString();
								isSpecialCell = (symbSpecials.indexOf(symbCell) != -1);
								symbIndex     = (isSpecialCell) ? symbSpecials.indexOf(symbCell) : symbEvents.indexOf(symbCell);								
								boxColourStr  = (isSpecialCell) ? specialBoxColours[symbIndex] : prizeColours[symbIndex];
								textColourStr = (isSpecialCell) ? specialTextColours[symbIndex] : colourBlack;

								r.push('<td>');
								showSymb(canvasIdStr, elementStr, cellWidth, boxColourStr, textColourStr, symbCell, !doRotate, !doTitle);
								r.push('</td>');
							}
							var rowText = '';
							for (var i = 0; i < symbolQty; i++)
							{
								if (arrSymbolCounts[rowIndex][i] > 2)
								{
									if (rowText.length > 0) 
									{
										rowText += " + ";
									}
									var prizeText = String.fromCharCode(i + 65) + arrSymbolCounts[rowIndex][i].toString();
									rowText += convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeText)];
								}
							}
							r.push('<td>');
							r.push(rowText);
							r.push('</td>');

							r.push('</tr>');
						}

						r.push('</table>');

						////////////////
						// Bonus Game //
						////////////////
						if (doBonusGame)
						{
							function showBonusTotal(A_arrPrizes)
							{
								var bCurrSymbAtFront = false;
								var iPrize      	 = 0;
								var iPrizeTotal 	 = 0;
					 			var strCurrSymb      = '';
								var strDecSymb  	 = '';
								var strThouSymb      = '';

								function getPrizeInCents(AA_strPrize)
								{
									var strPrizeWithoutCurrency = AA_strPrize.replace(new RegExp('[^0-9., ]', 'g'), '');
									var iPos 					= AA_strPrize.indexOf(strPrizeWithoutCurrency);
									var iCurrSymbLength 		= AA_strPrize.length - strPrizeWithoutCurrency.length;
									var strPrizeWithoutDigits   = strPrizeWithoutCurrency.replace(new RegExp('[0-9]', 'g'), '');

									strDecSymb 		 = strPrizeWithoutCurrency.substr(-3,1);									
									bCurrSymbAtFront = (iPos != 0);									
									strCurrSymb 	 = (bCurrSymbAtFront) ? AA_strPrize.substr(0,iCurrSymbLength) : AA_strPrize.substr(-iCurrSymbLength);
									strThouSymb      = (strPrizeWithoutDigits.length > 1) ? strPrizeWithoutDigits[0] : strThouSymb;

									return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
								}

								function getCentsInCurr(AA_iPrize)
								{
									var strValue = AA_iPrize.toString();

									strValue = strValue.substr(0,strValue.length-2) + strDecSymb + strValue.substr(-2);
									strValue = (strThouSymb != '') ? strValue.substr(0,strValue.length-6) + strThouSymb + strValue.substr(-6) : strValue;
									strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;

									return strValue;
								}

								for (var prizeIndex = 0; prizeIndex < A_arrPrizes.length; prizeIndex++)
								{
									iPrize = getPrizeInCents(A_arrPrizes[prizeIndex]);
									iPrizeTotal += iPrize;
								}

								r.push('<br>' + getTranslationByName("bonusPrize", translations) + ' : ' + getCentsInCurr(iPrizeTotal));
							}

							r.push('<p style="clear:both">' + getTranslationByName("bonusGame", translations) + '</p>');
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							////////////////
							// Bonus Game //
							////////////////
							r.push('<tr class="tablebody">');

							for (var symbIndex = 0; symbIndex < scenarioBonusGame.length; symbIndex++)
							{
								canvasIdStr = 'cvsTitleBonusTurn' + symbIndex.toString();
								elementStr  = 'eleTitleBonusTurn' + symbIndex.toString();
								cellStr     = convertedPrizeValues[getPrizeNameIndex(prizeNames, scenarioBonusGame[symbIndex])];

								if (((symbIndex) % 5) == 0)
								{
									r.push('</tr><tr>');
								}

								r.push('<td>');
								showSymb(canvasIdStr, elementStr, cellWidth, colourWhite, colourBlack, cellStr, !doRotate, !doTitle);
								r.push('</td>');
							}

							r.push('</tr>');
							r.push('</table>');

							/////////////////////
							// Bonus Game Wins //
							/////////////////////

							var bonusPrizes    = [];

							for (var prizeIndex = 0; prizeIndex < scenarioBonusGame.length; prizeIndex++)
							{
								bonusPrizeData = scenarioBonusGame[prizeIndex];
								bonusPrizes.push(convertedPrizeValues[getPrizeNameIndex(prizeNames, bonusPrizeData)]);
							}
							showBonusTotal(bonusPrizes);
						}

						r.push('<p></p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						if(debugFlag)
						{
							//////////////////////////////////////
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					function getScenario(jsonContext)
					{
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					function getPrizesData(scenario)
					{
						return scenario.split("|")[0];
					}

					function getMainGameData(scenario)
					{
						var outcomeData = scenario.split("|")[0];
						var outcomeSets = outcomeData.split(",");
						var result = [];
						for(var i = 0; i < outcomeSets.length; ++i)
						{
							result.push(outcomeSets[i]);
						}
						return result;
					}

					function getBonusGameData(scenario)
					{
						var outcomeData = scenario.split("|")[1];
						var outcomeSets = outcomeData.split(",");
						var result = [];
						for(var i = 0; i < outcomeSets.length; ++i)
						{
							result.push(outcomeSets[i]);
						}
						return result;
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
