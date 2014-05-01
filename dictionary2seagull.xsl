<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="1.0" encoding="ISO-8859-1" indent="yes"/>

<xsl:template match="dictionary">
  <protocol name="diameter-v1" type="binary" padding="4">
    <types>
      <xsl:for-each select="*/typedefn">
        <xsl:call-template name="resolve-type">
          <xsl:with-param name="name" select="@type-name" />
          <xsl:with-param name="type" select="." />
        </xsl:call-template>
      </xsl:for-each> 
      <typedef name="Grouped" type="grouped"></typedef>
    </types>

    <header name="command" length="msg-length" type="cmd-code">
      <fielddef name="protocol-version" size="1" unit="octet" />
      <fielddef name="msg-length" size="3" unit="octet" />
      <fielddef name="flags" size="1" unit="octet" />
      <fielddef name="cmd-code" size="3" unit="octet" />
      <fielddef name="application-id" size="4" unit="octet" />
      <fielddef name="HbH-id" size="4" unit="octet" />
      <fielddef name="EtE-id" size="4" unit="octet" />
    </header>
    
    <body>
      <header name="avp" length="avp-length" type="avp-code">
        <fielddef name="avp-code" size="4" unit="octet" />
        <fielddef name="flags" size="1" unit="octet" />
        <fielddef name="avp-length" size="3" unit="octet" />
        <optional>
          <fielddef name="Vendor-ID" size="4" unit="octet" condition="mask" field="flags" mask="128" />
        </optional>
      </header>
    </body>

    <dictionary>
      <avp>
        <xsl:for-each select="*/avp">
          <xsl:variable name="avp" select="." />
          <define name="{@name}">
            <xsl:choose>
              <xsl:when test="type">
                <xsl:attribute name="type"><xsl:value-of select="type/@type-name" /></xsl:attribute>
              </xsl:when>
              <xsl:when test="grouped">
                <xsl:attribute name="type">Grouped</xsl:attribute>
              </xsl:when>
            </xsl:choose>
            <setfield name="avp-code" value="{@code}" />
            <setfield name="flags" value="{number(@mandatory = 'must') * 128 + number(@vendor-bit = 'must') * 64 + number(@protected = 'must') * 32}" />
            <xsl:if test="@vendor-id">
              <setfield name="Vendor-ID" value="{/dictionary/*/vendor[@vendor-id = $avp/@vendor-id]/@code}" />
            </xsl:if>
          </define>
        </xsl:for-each>
      </avp>

      <command session-id="Session-Id" out-of-session-id="HbH-id">
        <xsl:for-each select="*/command">
          <define name="{@name}-Request">
            <setfield name="cmd-code" value="{@code}" />
            <setfield name="flags" value="128" />
            <setfield name="protocol-version" value="1" />
            <xsl:if test="../@id">
              <setfield name="application-id" value="{../@id}" />
            </xsl:if>
          </define>

          <define name="{@name}-Answer">
            <setfield name="cmd-code" value="{@code}" />
            <setfield name="flags" value="0" />
            <setfield name="protocol-version" value="1" />
            <xsl:if test="../@id">
              <setfield name="application-id" value="{../@id}" />
            </xsl:if>
          </define>
        </xsl:for-each>
      </command>
    </dictionary>
  </protocol>
</xsl:template>

<xsl:template name="resolve-type">
  <xsl:param name="name" />
  <xsl:param name="type" />
  <xsl:choose>
    <xsl:when test="$type/@type-name = 'Integer32'">
      <typedef name="{@type-name}" type="signed" size="4" unit="octet" />
    </xsl:when>
    <xsl:when test="$type/@type-name = 'Unsigned32'">
      <typedef name="{@type-name}" type="number" size="4" unit="octet" />
    </xsl:when>
    <xsl:when test="$type/@type-name = 'Time'">
      <typedef name="{@type-name}" type="number" size="4" unit="octet" />
    </xsl:when>
    <xsl:when test="$type/@type-name = 'Integer64'">
      <typedef name="{@type-name}" type="signed" size="8" unit="octet" />
    </xsl:when>
    <xsl:when test="$type/@type-name = 'Unsigned64'">
      <typedef name="{@type-name}" type="number" size="8" unit="octet" />
    </xsl:when>
    <xsl:when test="$type/@type-name = 'OctetString'">
      <typedef name="{@type-name}" type="string" size="4" unit="octet" />
    </xsl:when>
    <xsl:when test="$type/@type-name = 'Grouped'">
      <typedef name="{@type-name}" type="grouped" />
    </xsl:when>
    <xsl:when test="/dictionary/*/typedefn[@type-name = $type/@type-parent]">
      <xsl:call-template name="resolve-type">
        <xsl:with-param name="name" select="@type-name" />
        <xsl:with-param name="type" select="/dictionary/*/typedefn[@type-name = $type/@type-parent]" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <typedef name="{@type-name}">
        <xsl:comment>Unknown Type!</xsl:comment>
      </typedef>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
