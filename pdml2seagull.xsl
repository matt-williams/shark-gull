<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="1.0" encoding="ISO-8859-1" indent="yes"/>

<xsl:key name="ips" match="/pdml/packet/proto[@name = 'ip']/field[@name = 'ip.host']" use="@show" />

<xsl:template match="/">
  <scenario>
    <counter>
      <counterdef name="HbH-counter" init="0" />
      <counterdef name="EtE-counter" init="0" />
      <counterdef name="session-counter" init="0" />
    </counter>

    <init />

    <xsl:variable name="pdml" select="pdml" />
    <xsl:for-each select="pdml/packet/proto[@name = 'ip']/field[@name = 'ip.host' and generate-id() = generate-id(key('ips', @show)[1])]">
      <xsl:variable name="ip" select="@show" />
      <traffic>
        <xsl:comment>
          <xsl:value-of select="$ip" />
        </xsl:comment>
        <xsl:for-each select="$pdml/packet/proto[@name = 'diameter']">
          <xsl:choose>
            <xsl:when test="../proto[@name = 'ip']/field[@name = 'ip.src' and @show = $ip]">
              <send channel="peer-{../proto[@name = 'ip']/field[@name = 'ip.dst']/@show}">
                <action>
                  <inc-counter name="HbH-counter" />
                  <set-value name="HbH-id" format="$(HbH-counter)" />
                  <inc-counter name="EtE-counter" />
                  <set-value name="EtE-id" format="$(EtE-counter)" />
                  <xsl:if test="field[@name = 'diameter.avp']/field[@name = 'diameter.Session-Id']">
                    <inc-counter name="session-counter"/>
                    <set-value name="Session-Id" format="{field[@name = 'diameter.avp']/field[@name = 'diameter.Session-Id']/@show};$(session-counter)" />
                  </xsl:if>
                </action>

                <xsl:call-template name="command" />
              </send>
            </xsl:when>
            <xsl:when test="../proto[@name = 'ip']/field[@name = 'ip.dst' and @show = $ip]">
              <recv channel="peer-{../proto[@name = 'ip']/field[@name = 'ip.src']/@show}">
                <xsl:call-template name="command" />
              </recv>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </traffic>
    </xsl:for-each>

  </scenario>
</xsl:template>

<xsl:template name="command">
  <xsl:variable name="command" select="." />
  <command name="{document('dictionary.seagull.xml')/protocol/dictionary/command/define[
                    $command/field[@name = 'diameter.cmd.code']/@show = setfield[@name='cmd-code']/@value and
                    (($command/field[@name = 'diameter.applicationId']/@show = '0' and
                      not(setfield[@name='application-id'])) or
                     $command/field[@name = 'diameter.applicationId']/@show = setfield[@name='application-id']/@value) and
                    $command/field[@name = 'diameter.flags']/field[@name = 'diameter.flags.request']/@show * 128 = setfield[@name ='flags']/@value]/@name}">
    <xsl:call-template name="avps" />
  </command>
</xsl:template>

<xsl:template name="avps">
  <xsl:for-each select="field[@name = 'diameter.avp']">
    <xsl:variable name="avp" select="." />
    <xsl:variable name="avp-define" select="document('dictionary.seagull.xml')/protocol/dictionary/avp/define[
                                              $avp/field[@name = 'diameter.avp.code']/@show = setfield[@name='avp-code']/@value and
                                              (($avp/field[@name = 'diameter.avp.flags']/field[@name = 'diameter.flags.vendorspecific']/@show = '0' and
                                                not(setfield[@name='Vendor-ID'])) or
                                               $avp/field[@name = 'diameter.avp.vendorId']/@show = setfield[@name='Vendor-ID']/@value)]" />
    <xsl:variable name="avp-value" select="field[@name = concat('diameter.', $avp-define/@name)]" />
    <avp name="{$avp-define/@name}">
      <xsl:choose>
        <xsl:when test="$avp-value/*">
          <xsl:for-each select="$avp-value">
            <xsl:call-template name="avps" />
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="value"><xsl:value-of select="$avp-value/@show" /></xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    </avp>
  </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
